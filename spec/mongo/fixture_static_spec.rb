require 'spec_helper'

describe Mongo::Fixture do 
  describe 'Static methods' do
    describe ".path" do
      it "should return 'test/fixtures'" do
        Mongo::Fixture.path.should == "test/fixtures"
      end
    end

    describe ".path=" do
      it 'should set the path with the passed string' do
        Mongo::Fixture.path = "fixtures"
        Mongo::Fixture.path.should == "fixtures"
      end

      after do
        Mongo::Fixture.path = 'test/fixtures'
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

      context "a database connection and a valid fixture are passed but the store option is set to false" do 
        it "should not push" do
          database = double 'database'
          Mongo::Fixture.any_instance.stub :load
          Mongo::Fixture.any_instance.should_not_receive :push
          Mongo::Fixture.new :test, database, :store => false
        end
      end
    end
  end
end