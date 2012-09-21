Feature: Stash inserted fixtures
  In order to insert and rollback fixtures from command line
  As a mongo/ruby dev
  I want to be able to stash the ones I already inserted

Background: We have a database connection working
  Given a mongo database connection

Scenario: I save the done fixtures so to perform the rollbacks later
  Given a collection users
  And a file "test/fixtures/password/users.yaml" with: 
    """
    john:
      name: John 
      last_name: Wayne
    """
  And I load the password fixture to be stashed
  Then I should see 1 record in users with name "John" and last_name "Wayne" 
  When I rollback the stashed fixtures
  Then I should see 0 records in users