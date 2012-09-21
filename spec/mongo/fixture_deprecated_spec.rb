require 'spec_helper'

describe Mongo::Fixture do 
  describe 'Deprecated' do
    describe "#fixtures_path" do
      it "should raise a deprecation notice since 0.1.1, use Mongo::Fixture.path instead"
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

      it 'should be marked as deprecated' 
    end
  end
end