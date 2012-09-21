require 'spec_helper'

describe Mongo::Fixture do 
  describe 'Properties' do
    before do
      bla = stub 'bla'
      Mongo::Fixture.any_instance.stub :load
      Mongo::Fixture.any_instance.stub :push
      @f = Mongo::Fixture.new bla, bla
    end

    it 'should include Virtus' do
      Mongo::Fixture.ancestors.should include Virtus
    end

    it 'should have attribute :data' do 
      @f.attributes.keys.should include :data
    end

    it 'should have attribute :connection' do
      @f.attributes.keys.should include :connection
    end

    it 'should have attribute :name' do
      @f.attributes.keys.should include :name
    end

    it 'should have attribute :inserter' do
      @f.attributes.keys.should include :inserter
    end

    describe "#connection" do
      it "should return the Mongo connection passed as argument to the constructor" do
        Mongo::Fixture.any_instance.stub :push
        connection = stub
        fix = Mongo::Fixture.new nil, connection
        fix.connection.should === connection
      end
    end

    describe "#inserter" do
      it "should return an inserter with a reference to this" do
        database = double 'database'
        Mongo::Fixture.any_instance.stub :load
        fixture = Mongo::Fixture.new :test, database, false
        inserter = fixture.inserter
        inserter.should be_a Mongo::Fixture::Inserter 
        inserter.fixture.should === fixture
      end
    end

    describe '#name' do
      it 'should return the handler of the current fixture' do
        database = stub 'database'
        Mongo::Fixture.new(:handler, database).name.should == :handler
      end
    end
  end
end