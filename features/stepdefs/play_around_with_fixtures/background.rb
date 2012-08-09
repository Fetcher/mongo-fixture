# Feature: Play around with Fixtures
#   In order to test if Mongo::Fixture is really practical
#   As the gem developer
#   I want to play around with it a little bit
#
# Background: We have a database connection working
#   Given a mongo database connection

Given /^a mongo database connection$/ do
  @DB = Mongo::Connection.new.db "mongo-fixture-cucumber"
end
