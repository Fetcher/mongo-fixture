require "mongo-fixture"
require "pry"

describe Mongo::Fixture do
  describe ".path" do
    it "should return 'test/fixtures'" do
      Mongo::Fixture.path.should == "test/fixtures"
    end
  end

  describe ".new" do
    context "a symbol is sent representing a fixture" do
      it "should call load" do  
        Mongo::Fixture.any_instance.should_receive(:load).with :test
        Mongo::Fixture.new :test
      end
    end

    context "a database connection is passed" do
      it "should call push" do
        database = double 'mongodb'
        Mongo::Fixture.any_instance.stub :load
        Mongo::Fixture.any_instance.should_receive :push
        Mongo::Fixture.new :test, database
      end
    end    
    
    context "a database is provided but no fixture" do
      it "should not call push" do
        database = double 'database'
        Mongo::Fixture.any_instance.should_not_receive :push
        Mongo::Fixture.new nil, database
      end
    end
    
    context "a database connection and a valid fixture are passed but a false flag is passed at the end" do
      it "should not push" do
        database = double 'database'
        Mongo::Fixture.any_instance.stub :load
        Mongo::Fixture.any_instance.should_not_receive :push
        Mongo::Fixture.new :test, database, false
      end
    end
  end

  describe "#load" do
    context "there is a valid fixture folder setup" do
      before do
        Fast.file! "test/fixtures/test/users.yaml"
        Fast.file! "test/fixtures/test/actions.yaml"
      end

      it "should load the fixture YAML files using SymbolMatrix (third-party)" do
        fix = Mongo::Fixture.new
        fix.stub :check
        SymbolMatrix.should_receive(:new).with "test/fixtures/test/users.yaml"
        SymbolMatrix.should_receive(:new).with "test/fixtures/test/actions.yaml"
        fix.load :test
      end
            
      after do
        Fast.dir.remove! :test
      end
    end
    
    context "the check has been performed and I attempt to load another fixture" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "john: { name: John Doe }"
        Fast.file.write "test/fixtures/another/users.yaml", "john: { name: John Doe }"
      end

      it "should fail" do
        Mongo::Fixture.any_instance.stub :push
        database = double 'database'
        database.stub(:[]).and_return double(:count => 0 )
        fix = Mongo::Fixture.new :test, database
        fix.check
        expect { fix.load :another
        }.to raise_error Mongo::Fixture::LoadingFixtureIllegal, 
          "A check has already been made, loading a different fixture is illegal"
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
  end
  
  describe "#force_checked!" do
    it "check should return true and should not call [] in the passed database" do
      database = stub 'database'
      database.should_not_receive :[]
      
      Mongo::Fixture.any_instance.stub :load
      fix = Mongo::Fixture.new :anything, database, false
      fix.force_checked!.should === true
      fix.check.should === true
    end
  end
  
  describe "#[]" do
    context "a valid fixture has been loaded" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "john: { name: John, last_name: Wayne }"
        Fast.file.write "test/fixtures/test/actions.yaml", "walk: { user_id: 1, action: Walks }"
        @fix = Mongo::Fixture.new
        @fix.stub :check
        @fix.load :test
      end
      
      context "a collection key is passed" do
        it "should return the SymbolMatrix containing the same info as in the matching YAML file" do
          @fix[:users].should be_a SymbolMatrix
          @fix[:users].john.name.should == "John"
          @fix[:users].john.last_name.should == "Wayne"
          
          @fix[:actions].walk.action.should == "Walks"
        end
      end
      
      after do
        Fast.dir.remove! :test
      end
    end    
  end
  
  describe "#method_missing" do
    context "a valid fixture has been loaded" do
      context "a collection key is passed" do
        before do
          Fast.file.write "test/fixtures/test/users.yaml", "john: { name: John, last_name: Wayne }"
          Fast.file.write "test/fixtures/test/actions.yaml", "walk: { user_id: 1, action: Walks }"
          @fix = Mongo::Fixture.new
          @fix.stub :check
          @fix.load :test
        end
        
        it "should return the SymbolMatrix containing the same info as in the matching YAML file" do
          @fix.users.should be_a SymbolMatrix
          @fix.users.john.name.should == "John"
          @fix.users.john.last_name.should == "Wayne"
          
          @fix.actions.walk.action.should == "Walks"          
        end
        
        after do
          Fast.dir.remove! :test
        end
      end
    end    
    
    it "should raise no method error if matches nothing" do
      expect { Mongo::Fixture.new.nothing = "hola"
      }.to raise_error NoMethodError
    end
  end
  
  describe "#fixtures_path" do
    it "should call Mongo::Fixture.path" do
      Mongo::Fixture.should_receive :path
      Mongo::Fixture.new.fixtures_path
    end
  end

  describe "#check" do
    it "should count records on all the used collections" do
      Mongo::Fixture.any_instance.stub :push         # push doesn't get called
      
      database = double 'mongodb'                    # Fake database connection
      counter = stub                                 # fake collection
      
      database.should_receive(:[]).with(:users).and_return counter
      database.should_receive(:[]).with(:actions).and_return counter
      counter.should_receive(:count).twice.and_return 0
      
      fix = Mongo::Fixture.new nil, database
      collections = [:users, :actions]
      def fix.stub_data
        @data = { :users => nil, :actions => nil }
      end
      fix.stub_data
      
      fix.check
    end
    
    it "should raise error if the count is different from 0" do
      database = double "mongodb"
      counter = stub
      counter.should_receive(:count).and_return 4
      database.stub(:[]).and_return counter
      Mongo::Fixture.any_instance.stub :push
      
      fix = Mongo::Fixture.new nil, database
      def fix.stub_data
        @data = { :users => nil}
      end
      fix.stub_data
      
      expect { fix.check
      }.to raise_error Mongo::Fixture::CollectionsNotEmptyError, 
        "The collection 'users' is not empty, all collections should be empty prior to testing"
    end
    
    it "should return true if all collections count equals 0" do
      counter  = stub :count => 0
      database = stub
      database.should_receive(:[]).with(:users).and_return counter
      database.should_receive(:[]).with(:actions).and_return counter

      Mongo::Fixture.any_instance.stub :push
      
      fix = Mongo::Fixture.new nil, database
      def fix.stub_data
        @data = { :users => nil, :actions => nil }
      end
      fix.stub_data
      
      fix.check.should === true
    end
    
    context "the check has been done and it passed before" do
      it "should return true even if now collections don't pass" do
        Mongo::Fixture.any_instance.stub :push
        
        @counter = double 'counter'
        @counter.stub :count do
          @amount ||= 0
          @amount += 1
          0 unless @amount > 5
        end
        
        @database = double 'database'
        @database.stub(:[]).and_return @counter

        @fix = Mongo::Fixture.new nil, @database
        def @fix.stub_data
          @data = { :users => nil, :tables => nil, :actions => nil, :schemas => nil }
        end
        @fix.stub_data
        @fix.check.should === true
        @fix.check.should === true  # This looks confusing: let explain. The #count method as defined for the mock
                                    # runs 4 times in the first check. In the second check, it runs 4 times again.
                                    # After time 6 it returns a large amount, making the check fail.
                                    # Of course, the fourth time is never reached since the second check is skipped
      end
    end
    
    context "no fixture has been loaded" do
      it "should fail with a missing fixture exception" do
        fix = Mongo::Fixture.new
        expect { fix.check
        }.to raise_error Mongo::Fixture::MissingFixtureError,
          "No fixture has been loaded, nothing to check"
      end
    end
    
    context "a valid fixture has been loaded but no connection has been provided" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "jane { name: Jane Doe }"
      end
      it "should fail with a missing database connection exception" do
        fix = Mongo::Fixture.new :test
        expect { fix.check
        }.to raise_error Mongo::Fixture::MissingConnectionError, 
          "No connection has been provided, impossible to check"
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
    
    context "a database is provided but no fixture" do
      it "should fail with a missing fixture exception" do
        database = double 'database'
        fix = Mongo::Fixture.new nil, database
        expect { fix.check 
        }.to raise_error Mongo::Fixture::MissingFixtureError,
          "No fixture has been loaded, nothing to check"
      end
    end
  end

  describe "#connection" do
    it "should return the Mongo connection passed as argument to the constructor" do
      Mongo::Fixture.any_instance.stub :push
      connection = stub
      fix = Mongo::Fixture.new nil, connection
      fix.connection.should === connection
    end
  end
  
  describe "#connection=" do
    it "sets the connection" do
      fix = Mongo::Fixture.new
      connection = stub
      fix.connection = connection
      fix.connection.should === connection
    end
    
    context "a check has been performed and I attempt to change the connection" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "jane { name: Secret }"
      end
      
      it "should fail" do
        database = double 'database'
        database.stub(:[]).and_return mock(:count => 0)
        Mongo::Fixture.any_instance.stub :push
        fix = Mongo::Fixture.new :test, database
        fix.check
        expect { fix.connection = double 'database'
        }.to raise_error Mongo::Fixture::ChangingConnectionIllegal, 
          "A check has already been performed, changing the connection now is illegal"
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
  end
  
  describe "#data" do
    context "a fixture has been loaded" do
      before do 
        Fast.file.write "test/fixtures/test/users.yaml", "jane { name: Jessica Dore }"
      end
      
      it "should return the fixture data" do
        fix = Mongo::Fixture.new :test
        fix.data.should have_key :users
        fix.data[:users].should be_a SymbolMatrix
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
    
    context "no fixture has been loaded" do
      it "should return nil" do
        fix = Mongo::Fixture.new 
        fix.data.should be_nil
      end
    end
  end
  
  describe "#push" do
    it "should call #check" do
      fix = Mongo::Fixture.new
      def fix.stub_data
        @data = {}
      end
      fix.stub_data
      fix.should_receive :check
      fix.push
    end

    context "a valid fixture and a database connection are provided" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "john: { name: John, last_name: Wayne }"
        Fast.file.write "test/fixtures/test/actions.yaml", "walk: { user_id: 1, action: Walks }"
        @collection    = stub
        @database = stub :[] => @collection
        @fix = Mongo::Fixture.new
        @fix.load :test
        @fix.connection = @database
      end
    
      it "should attempt to insert the data into the database" do
        @collection.stub :count => 0
        @collection.should_receive(:insert).with :name => "John", :last_name => "Wayne"
        @collection.should_receive(:insert).with :user_id => 1, :action => "Walks"
        @fix.push
      end
      
      after do
        Fast.dir.remove! :test
      end
    end    
    
    context "a fixture with a field with a <raw> and a <processed> alternative" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "user: { password: { raw: secret, processed: 35ferwt352 } }"
      end
      
      it "should insert the <processed> alternative" do
        database = double 'database'
        insertable = double 'collection'
        insertable.stub :count => 0
        insertable.should_receive(:insert).with :password => '35ferwt352'
        database.stub(:[]).and_return insertable
        fix = Mongo::Fixture.new :test, database, false
        fix.push
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
    
    context "a fixture with a field with alternatives missing the <processed> and the option doesn't match a collection" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "hey: { pass: { raw: There } }"
      end
      
      it "should fail" do
        database = double 'database', :[] => stub( 'collection', :count => 0, :drop => nil  )
        fix = Mongo::Fixture.new :test, database, false
        expect { fix.push
        }.to raise_error Mongo::Fixture::MissingProcessedValueError, 
          "In record 'hey' to be inserted into 'users', the processed value of field 'pass' is missing, aborting"
      end
      
      
      it "should call the rollback" do
        database = double 'database', :[] => stub( 'collection', :count => 0, :drop => nil )
        fix = Mongo::Fixture.new :test, database, false
        fix.should_receive :rollback
        expect { fix.push
        }.to raise_error Mongo::Fixture::MissingProcessedValueError
      end      
      
      after do
        Fast.dir.remove! :test
      end
    end
    
    context "a fixture with a field with one alternative name matches a collection name" do
      context "the alternative value matches a record and in the collection" do
        before do 
          Fast.file.write "test/fixtures/test/users.yaml", "pepe: { name: Jonah }"
          Fast.file.write "test/fixtures/test/comments.yaml", "flamewar: { user: { users: pepe }, text: 'FLAME' }"
        end
        
        it "should insert the comment so that the comment user value matches the '_id' of the user" do
          database = double 'database'
          comm = double 'comments', :count => 0, :drop => nil
          comm.should_receive( :insert ).with( :user => "un id", :text => "FLAME" )
          record = stub 'record'
          record.should_receive( :[] ).with( :_id ).and_return "un id"
          usrs = double 'users', :count => 0, :find => stub( :first => record ), :drop => nil, :insert => nil
          database.stub :[] do |coll|
            case coll
              when :users
                usrs
              when :comments
                comm
            end
          end
          fix = Mongo::Fixture.new :test, database
        end
        
        context "the collection is ordered so that the comment collection comes before the users one" do
          it "should stop and process the users first" do
            database = double 'database'
            usrs = double 'users', :count => 0, :insert => nil, :find => stub( :first => stub( :[] => "un id" ) )
            database.stub :[] do |argument|
              case argument
                when :comments
                  double 'comments', :count => 0, :insert => nil
                when :users
                  usrs
              end
            end
            fix = Mongo::Fixture.new :test, database, false
            def fix.stub_data
              @data = {
                :comments => SymbolMatrix.new("test/fixtures/test/comments.yaml"),
                :users => SymbolMatrix.new("test/fixtures/test/users.yaml") }
            end
            fix.stub_data
            
            fix.push
          end
        end
        
        after do
          Fast.dir.remove! :test
        end
      end      
    end
  end
  
  describe "#data_was_inserted_in?" do
    it "should be private" do
      fix = Mongo::Fixture.new
      fix.private_methods(false).should include :data_was_inserted_in?
    end
    
    context "there is a simple fixture and a collection has been inserted by this fixture" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "pepe: { user: pepe }"
      end
      
      it "should return true" do
        database = double 'database'
        coll = double 'collection', :count => 0, :insert => nil
        database.stub :[] => coll
        fix = Mongo::Fixture.new :test, database
        def fix.loot
          data_was_inserted_in?(:users).should === true
        end
        fix.loot
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
        def fix.loot
          data_was_inserted_in?(:comment).should === false
        end
        fix.loot
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
  end
  
  # This should go in a dependency, pending refactoring TODO
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
        
        fix = Mongo::Fixture.new
        def fix.stub_data
          @data = {}
        end
        fix.stub_data
        simplified = fix.simplify base_hash
        simplified.should == {
          :name => "Jane",
          :band => "Witherspoons",
          :pass => "53oih7fhjdgj3f8=",
          :email => "jane@gmail.com"
        }
      end
    end
    
    context "the multidimensional array is missing the processed part of the field" do
      it "should raise an exception" do
        base_hash = {
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
        
        fix = Mongo::Fixture.new
        def fix.stub_data
          @data = {}
        end
        fix.stub_data
        expect { fix.simplify base_hash
        }.to raise_error Mongo::Fixture::MissingProcessedValueError, 
          "The processed value to insert into the db is missing from the field 'pass', aborting"
      end
    end
  end
  
  describe "#rollback" do
    it "should check" do
      fix = Mongo::Fixture.new
      def fix.stub_data
        @data = {}
      end
      fix.stub_data
      fix.should_receive :check
      fix.rollback
    end
    
    context "the check is failing" do
      it "should raise a custom error for the rollback" do
        fix = Mongo::Fixture.new
        fix.stub(:check).and_raise Mongo::Fixture::CollectionsNotEmptyError
        expect { fix.rollback
        }.to raise_error Mongo::Fixture::RollbackIllegalError, 
          "The collections weren't empty to begin with, rollback aborted."
      end
    end
    
    context "a check has been done and is passing" do    
      before do 
        @database = stub
        @truncable = stub
        @truncable.stub :count => 0
        @database.stub(:[]).and_return @truncable
        
        @fix = Mongo::Fixture.new
        @fix.connection = @database
        def @fix.stub_data
          @data = { :users => nil, :actions => nil, :extras => nil }
        end
        @fix.stub_data
        
        @fix.check.should === true
      end
      
      it "should call drop on each of the used collections" do
        @truncable.should_receive(:drop).exactly(3).times
        @fix.rollback
      end
    end
  end
end
