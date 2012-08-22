require "spec_helper"

describe Mongo::Fixture::Inserter do
  describe ".new" do
    it "should accept an argument" do
      Mongo::Fixture::Inserter.new double "fixture"
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
        fixture = double 'fixture', :data => {}
        ins = Mongo::Fixture::Inserter.new fixture
        expect { ins.simplify base_hash
        }.to raise_error Mongo::Fixture::MissingProcessedValueError, 
          "The processed value to insert into the db is missing from the field 'pass', aborting"
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
        ins = Mongo::Fixture::Inserter.new fix
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
    context "provided a the collection has data in the fixture" do
      it "should insert the data of the collection using the fixture's connection"

      it "should add the collection as inserted"
    end
  end
end