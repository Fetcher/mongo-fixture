require "spec_helper"

describe Mongo::Fixture::Inserter do
  describe ".new" do
    it "should accept an argument" do
      Mongo::Fixture::Inserter.new double "fixture"
    end
  end

  describe "#simplify" do
    context "when receiving a multidimensional hash containing a field with raw and processed" do
      it "should convert it in a simple hash using the processed value as replacement" do
        base_hash = {
          :name => "Jane",
          :band => "Witherspoons",
          :pass => {
            :raw => "secret",
            :processed => "53oih7fhjdgj3f8="
          },
          :email => {
            :raw => "Jane@gmail.com ",
            :processed => "jane@gmail.com"
          }
        }
        fixture = double 'fixture', :data => {}

        ins = Mongo::Fixture::Inserter.new fixture
        simplified = ins.simplify base_hash
        simplified.should == {
          :name => "Jane",
          :band => "Witherspoons",
          :pass => "53oih7fhjdgj3f8=",
          :email => "jane@gmail.com"
        }
      end
    end
    
    context "the multidimensional array is missing the processed part of the field" do
      before do
        @base_hash = {
          :name => "Jane",
          :pass => {
            :raw => "secret",
            :not_processed => "53oih7fhjdgj3f8="
          },
          :email => {
            :raw => "Jane@gmail.com ",
            :processed => "jane@gmail.com"
          }
        }
      end

      it "should raise an exception" do
        fixture = double 'fixture', :data => {}, :rollback => nil
        ins = Mongo::Fixture::Inserter.new fixture
        expect { ins.simplify @base_hash
        }.to raise_error Mongo::Fixture::ReferencedRecordNotFoundError
      end

      it "should call #resolve_field_hash with the data hash" do
        fixture = double 'fixture', :data => {}
        ins = Mongo::Fixture::Inserter.new fixture
        ins.should_receive(:resolve_field_hash).with :raw => "secret", :not_processed => "53oih7fhjdgj3f8="
        ins.should_receive(:resolve_field_hash).with :raw => "Jane@gmail.com ", :processed => "jane@gmail.com"        
        ins.simplify @base_hash
      end
    end
  end

  describe "#resolve_field_hash" do
    context "the data is not a hash" do
      it "should raise a wrong argument exception" do
        inserter = Mongo::Fixture::Inserter.new double 'fixture'
        expect { inserter.resolve_field_hash "not a hash"
        }.to raise_error ArgumentError, "Hash expected"
      end
    end

    context "at leasts one key matches a collection name" do
      context "no record name matches an existing record in target collection" do
        before do
          @data = { 
            :users => { :pepe => { :name => "Jose" } },
            :comments => { :demo => { :text => "Hola", :user => { :users => "lula" } } }
          }
        end

        it "should raise an exception" do
          coll = double "collection", :insert => nil
          connection = double "connection", :[] => coll
          fixture = double 'fixture', :data => @data, :connection => connection
          inserter = Mongo::Fixture::Inserter.new fixture
          expect { inserter.resolve_field_hash :users => "lula"
          }.to raise_error Mongo::Fixture::ReferencedRecordNotFoundError, 
            "The collection 'users' doesn't include the record 'lula'"
        end
      end
    end

    context "many to many associations" do
      before do 
        @data = {
          :users => {
            :pepe => {
              :username => "jose",
              :pass => "secret"
            },
            :lula => {
              :username => "lula",
              :pass => {
                :raw => "moresecret",
                :processed => "asdfhjlueiwywhetkjtret66666666"
              }
            }
          },
          :admins => {
            :superadmin => {
              :login => "super"
            }
          },
          :comments => {
            :demo => {
              :text => "Simple text",
              :user => {
                :users => [ "pepe", "lula" ],
                :admins => "superadmin"
              }
            },
            :another => {
              :text => "Die another day",
              :user => {
                :users => "pepe"
              }
            }
          }
        }
      end

      it "should send to each comment the respective ids" do
        pepe_id = "ladjsfljasf"
        lula_id = "gsuyhkasrhte"
        superadmin_id = "323454"

        lula_record_data = double "lula record data"
        lula_record_data.should_receive( :[] ).with("_id").and_return lula_id
        lula_record = double "lula record", :first => lula_record_data
        pepe_record_data = double "pepe record data"
        pepe_record_data.should_receive(:[]).twice.with("_id").and_return(pepe_id)
        pepe_record = double "pepe record"
        pepe_record.should_receive(:first).twice.and_return pepe_record_data
        admin_record_data = double "admin record data"
        admin_record_data.should_receive(:[]).with("_id").and_return superadmin_id
        admin_record = double "admin record", :first => admin_record_data
        admins = double "admins", :insert => nil
        admins.should_receive(:find).with( :login => "super" ).and_return admin_record
        users = double 'users', :insert => nil
        users.should_receive(:find).twice.with( :username => "jose", :pass => "secret" ).and_return pepe_record
        users.should_receive(:find).with( :username => "lula", :pass => "asdfhjlueiwywhetkjtret66666666" ).and_return lula_record
        connection = double 'connection'
        connection.should_receive(:[]).exactly(5).times.with(:users).and_return users
        connection.should_receive(:[]).twice.with(:admins).and_return admins
        fixture = double 'fixture', :data => @data, :connection => connection
        inserter = Mongo::Fixture::Inserter.new fixture
        inserter.resolve_field_hash( :users => [ "pepe", "lula" ] ).should == [ pepe_id, lula_id ]
        inserter.resolve_field_hash( :admins => "superadmin" ).should == superadmin_id
        inserter.resolve_field_hash( :users => "pepe" ).should == pepe_id
      end

      context "some user is missing" do
        before do
          @data = {
            :users => {
              :pepe => {
                :username => "jose",
                :pass => "secret"
              },
              :lula => {
                :username => "lula",
                :pass => {
                  :raw => "moresecret",
                  :processed => "asdfhjlueiwywhetkjtret66666666"
                }
              }
            },
            :comments => {
              :demo => {
                :text => "Simple text",
                :user => {
                  :users => [ "pepe", "lula", "noexiste" ],
                }
              },
            }
          }
        end

        it "should raise an exception" do
          pepe_id = "ladjsfljasf"
          lula_id = "gsuyhkasrhte"

          lula_data = double "lula_data"
          lula_data.should_receive(:[]).with("_id").and_return lula_id
          lula = double "lula", :first => lula_data
          pepe_data = double "pepe_data"
          pepe_data.should_receive(:[]).with("_id").and_return pepe_id
          pepe = double "pepe", :first => pepe_data
          users = double "users", :insert => nil
          users.should_receive(:find).with( :username => "jose", :pass => "secret" ).and_return pepe
          users.should_receive(:find).with( :username => "lula", :pass => "asdfhjlueiwywhetkjtret66666666" ).and_return lula
          connection = double "connection"
          connection.should_receive(:[]).exactly(4).times.with(:users).and_return users
          fixture = double "fixture", :data => @data, :connection => connection
          inserter = Mongo::Fixture::Inserter.new fixture
          expect { inserter.resolve_field_hash( :users => [ "pepe", "lula", "noexiste" ] )
          }.to raise_error Mongo::Fixture::ReferencedRecordNotFoundError, 
            "The collection 'users' doesn't include the record 'noexiste'"
        end
      end
    end

    context "reference from one record to another" do
      context "the key matches a collection name" do
        context "the referenced record exists" do
          it "should call #data_was_inserted_in? with the collections name" do
            @data = { 
              :users => { :pepe => { :name => "Jose" } },
              :comments => { :demo => { :text => "hola", :user => {:users => "pepe" } } }
            }

            pepe_data = double "pepe_data", :[] => nil
            pepe = double "pepe", :insert => nil
            pepe.should_receive(:find).with(:name => "Jose").and_return double"pepeee", :first => pepe_data
            connection = double "connection"
            connection.should_receive(:[]).twice.with(:users).and_return pepe
            fixture = double "fixture", :data => @data, :connection => connection
            inserter = Mongo::Fixture::Inserter.new fixture
            inserter.should_receive(:data_was_inserted_in?).twice.with(:users)
            inserter.resolve_field_hash(:users => "pepe")
          end

          context "the data wasn't inserted into users" do
            it "should call #insert_data_for with the collections name" do
              @data = { 
                :users => { :pepe => { :name => "Jose" } },
                :comments => { :demo => { :text => "hola", :user => {:users => "pepe" } } }
              }

              pepe_data = double "pepe_data", :[] => nil
              pepe = double "pepe"
              pepe.should_receive(:find).with(:name => "Jose").and_return double"pepeee", :first => pepe_data
              connection = double "connection"
              connection.should_receive(:[]).with(:users).and_return pepe
              fixture = double "fixture", :data => @data, :connection => connection
              inserter = Mongo::Fixture::Inserter.new fixture
              inserter.should_receive(:insert_data_for).with(:users)
              inserter.resolve_field_hash(:users => "pepe")
            end
          end

          context "the data was inserted into users" do
            it "should NOT call #insert_data_for with the collections name" do
              @data = { 
                :users => { :pepe => { :name => "Jose" } },
                :comments => { :demo => { :text => "hola", :user => {:users => "pepe" } } }
              }

              pepe_data = double "pepe_data", :[] => nil
              pepe = double "pepe"
              pepe.should_receive(:find).with(:name => "Jose").and_return double"pepeee", :first => pepe_data
              connection = double "connection"
              connection.should_receive(:[]).with(:users).and_return pepe
              fixture = double "fixture", :data => @data, :connection => connection
              inserter = Mongo::Fixture::Inserter.new fixture
              inserter.should_receive(:insert_data_for).with(:users)
              inserter.resolve_field_hash(:users => "pepe")
            end
          end


          it "should return the object id of the referenced record" do
            @data = { 
              :users => { :pepe => { :name => "Jose" } },
              :comments => { :demo => { :text => "hola", :user => {:users => "pepe" } } }
            }

            actual_record = double "actual_record"
            actual_record.should_receive(:[]).with("_id").and_return "un id"
            record_from_db = double 'record from db', :first => actual_record

            collection = double 'collection', :insert => nil
            collection.should_receive(:find).with(:name => "Jose").and_return record_from_db
            fixture = double 'fixture', :data => @data, :connection => double( :[] =>  collection)
            inserter = Mongo::Fixture::Inserter.new fixture
            inserter.resolve_field_hash( :users => "pepe" ).should == "un id"
          end
        end

        context "the referenced record exists, but have complex field values" do
          it "should return the object id of the referenced record" do
            @data = { 
              :users => { :pepe => { :name => "Jose", :pass => { :raw => "a", :processed => "234" } } },
              :comments => { :demo => { :text => "hola", :user => {:users => "pepe" } } }
            }

            actual_record = double "actual_record"
            actual_record.should_receive(:[]).with("_id").and_return "un id"
            record_from_db = double 'record from db', :first => actual_record

            collection = double 'collection', :insert => nil
            collection.should_receive(:find).with(:name => "Jose", :pass => "234").and_return record_from_db
            fixture = double 'fixture', :data => @data, :connection => double( :[] =>  collection)
            inserter = Mongo::Fixture::Inserter.new fixture
            inserter.resolve_field_hash( :users => "pepe" ).should == "un id"
          end
        end


        context "the referenced record does not exist" do
          it "should raise an error" do
            data = { :users => "user" }
            inserter = Mongo::Fixture::Inserter.new double 'fixture', :data => {}
            expect { inserter.resolve_field_hash data
            }.to raise_error Mongo::Fixture::ReferencedRecordNotFoundError, 
              "This fixture does not include data for the collections [users]"
          end
        end
      end

      context "no key matches a collection name" do
        it "should raise an error" do
          data = { :users => "user", :comments => "comment"}
          fixture = stub 'fixture', :data => { :collection => "", :another_collection => ""}
          inserter = Mongo::Fixture::Inserter.new fixture
          expect { inserter.resolve_field_hash data
          }.to raise_error Mongo::Fixture::ReferencedRecordNotFoundError,
            "This fixture does not include data for the collections [users,comments]"
        end
      end
    end

    context "there is a :processed key" do
      it "should return the value of the :processed field" do
        data = { :raw => "hello", :processed => "hash" }
        inserter = Mongo::Fixture::Inserter.new double "fixture"
        inserter.resolve_field_hash(data).should == "hash"
      end
    end
  end

  describe "#data_was_inserted_in?" do
    context "there is a simple fixture and a collection has been inserted by this fixture" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "pepe: { user: pepe }"
      end
      
      it "should return true" do
        database = double 'database'
        coll = double 'collection', :count => 0, :insert => nil
        database.stub :[] => coll
        fix = Mongo::Fixture.new :test, database
        ins = fix.inserter
        ins.data_was_inserted_in?(:users).should === true
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
    
    context "there is a simple fixture and a collection was inserted but not this" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "pepe: { user: pepe }"
      end
      
      it "should return false" do
        database = double 'database'
        coll = double 'collection', :count => 0, :insert => nil
        database.stub :[] => coll
        fix = Mongo::Fixture.new :test, database
        ins = Mongo::Fixture::Inserter.new fix
        def ins.loot
          data_was_inserted_in?(:comment).should === false
        end
        ins.loot
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
  end  

  describe "#insert_data_for" do
    context "provided the collection has data in the fixture" do
      it "should insert the data of the collection using the fixture's connection" do
        @data = { :users => { :pepe => { :name => "Jose" } } }
        collection = double "collection"
        collection.should_receive(:insert).with( :name => "Jose" )
        connection = double 'connection'
        connection.should_receive(:[]).with(:users).and_return collection
        fixture = double "fixture", :data => @data
        fixture.should_receive(:connection).and_return connection
        inserter = Mongo::Fixture::Inserter.new fixture
        inserter.insert_data_for :users
      end

      it "should add the collection as inserted" do
        @data = { :users => { :pepe => { :name => "Jose" } } }
        collection = double "collection"
        collection.should_receive(:insert).with( :name => "Jose" )
        connection = double 'connection'
        connection.should_receive(:[]).with(:users).and_return collection
        fixture = double "fixture", :data => @data
        fixture.should_receive(:connection).and_return connection
        inserter = Mongo::Fixture::Inserter.new fixture
        inserter.insert_data_for :users
        inserter.inserted.should include :users
      end
    end
  end

  describe "#fixture" do
    it "should return the fixture" do
      fixture = double "fixture"
      inserter = Mongo::Fixture::Inserter.new fixture
      inserter.fixture.should === fixture
    end
  end
end