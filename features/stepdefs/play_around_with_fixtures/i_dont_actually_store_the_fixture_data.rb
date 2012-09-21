When /^I load the ([\w_]+) fixture without storing it$/ do |fixture_name|
  @fixture = Mongo::Fixture.new fixture_name.to_sym, @DB, :store => false
end

Then /^I should see in the fixture object the data of the record "(\w+)" in "(\w+)":$/ do |record, collection, data|
  data = SymbolMatrix.new data
  data.each do |key, value|
    @fixture.send(collection.to_sym).send(record.to_sym).should have_key key
    @fixture.send(collection.to_sym).send(record.to_sym)[key].should == value
  end
end