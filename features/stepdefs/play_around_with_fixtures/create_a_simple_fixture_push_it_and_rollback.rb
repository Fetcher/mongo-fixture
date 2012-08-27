#Scenario: Create a simple fixture, push it and rollback
#  Given a collection visitors
#  And a collection aliens
#  And a collection visits
#  And a file "test/fixtures/simple/visitors.yaml" with:
#    """
#    anonymous:
#      name: V
#      email: v@for.vendetta
#    """
#  And a file "test/fixtures/simple/aliens.yaml" with:
#    """
#    yourfavouritemartian:
#      race: Zerg
#    """
#  And a file "test/fixtures/simple/visits.yaml" with:
#    """
#    v2yfm:
#      alien_id: 1
#      visitor_id: 1
#    """
#  When I load the simple fixture
#  Then I should see 1 record in visitors with name "V" and email "v@for.vendetta"
#  And I should see 1 record in aliens with race "Zerg"
#  And I should see 1 record in visits with alien_id 1 and visitor_id 1
#  When I rollback
#  Then I should see 0 records in visitors
#  And I should see 0 records in aliens
#  And I should see 0 records in visits

Given /^a collection (\w+)$/ do |collection|
  @DB[collection]
end

And /^a file "(.+?)" with:$/ do |file, content|
  Fast.file.write file, content
end

When /^I load the (\w+) fixture$/ do |fixture|
  #binding.pry
  @fixture = Mongo::Fixture.new fixture.to_sym, @DB
end

Then /^I should see (\d+) record in (\w+) with (\w+) "([^"]+)" and (\w+) "(.+?)"$/ do 
  |amount, collection, field1, data1, field2, data2|
  
  @DB[collection].find( field1 => data1, field2 => data2 ).count.should == amount.to_i
end

And /^I should see (\d+) record in (\w+) with (\w+) "([^"]+)"$/ do 
  |amount, collection, field, data|
  
  @DB[collection].find( field => data ).count.should == amount.to_i
end

Then /^I should see (\d+) record in (\w+) with (\w+) (\d+) and (\w+) (\d+)$/ do 
  |amount, collection, field1, data1, field2, data2|
  
  @DB[collection].find( field1 => data1.to_i, field2 => data2.to_i ).count.should == amount.to_i
end

When /^I rollback$/ do
  @fixture.rollback
end

Then /^I should see (\d+) records in (\w+)$/ do |amount, collection|
  @DB[collection].count.should == amount.to_i
end

And /^the user named "(\w+)" should have in documents the id of the one titled "(\w+)"$/ do 
  |name, title|
  user = @DB[:users].find_one :name => name
  document = @DB[:documents].find_one :title => title
  user["documents"].should include document["_id"]
end