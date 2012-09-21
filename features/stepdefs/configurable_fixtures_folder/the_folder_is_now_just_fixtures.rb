When /^I set the fixtures path as "(.*?)"$/ do |path|
  Mongo::Fixture.path = path
end