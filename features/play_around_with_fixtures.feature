Feature: Play around with Fixtures
  In order to test if Mongo::Fixture is really practical
  As the gem developer
  I want to play around with it a little bit

Background: We have a database connection working
  Given a mongo database connection

Scenario: Create a simple fixture, push it and rollback
  Given a collection visitors
  And a collection aliens
  And a collection visits
  And a file "test/fixtures/simple/visitors.yaml" with:
    """
    anonymous:
      name: V
      email: v@for.vendetta
    """
  And a file "test/fixtures/simple/aliens.yaml" with:
    """
    yourfavouritemartian:
      race: Zerg
    """
  And a file "test/fixtures/simple/visits.yaml" with:
    """
    v2yfm:
      alien_id: 1
      visitor_id: 1
    """
  When I load the simple fixture
  Then I should see 1 record in visitors with name "V" and email "v@for.vendetta"
  And I should see 1 record in aliens with race "Zerg"
  And I should see 1 record in visits with alien_id 1 and visitor_id 1
  When I rollback
  Then I should see 0 records in visitors
  And I should see 0 records in aliens
  And I should see 0 records in visits

Scenario: The users collection has a password field
  Given a collection users
  And a file "test/fixtures/password/users.yaml" with: 
    """
    john:
      name: John Wayne
      password:
        raw: secret
        processed: 5bfb52c459cdb07218c176b5ddec9b6215bd5b76
    """
  When I load the password fixture
  Then I should see 1 record in users with name "John Wayne" and password "5bfb52c459cdb07218c176b5ddec9b6215bd5b76"    
  When I rollback
  Then I should see 0 records in users

Scenario: Misconfigured password field
  Given a collection users
  And a file "test/fixtures/misconfigured/users.yaml" with:
    """
    good_entry:
      password:
        raw: secret
        processed: 96bdg756n5sgf9gfs==
    wrong_entry:
      password:
        missing: The field
    """
  Then the loading of misconfigured fixture should fail
  And I should see that the collection was "users"
  And I should see that the field was "password"
  And I should see that the entry was "wrong_entry"
  And I should see 0 records in users

Scenario: I save the done fixtures so to perform the rollbacks later
  Given a collection users
  And a file "test/fixtures/password/users.yaml" with: 
    """
    john:
      name: John 
      last_name: Wayne
    """
  And I load the password fixture
  Then I should see 1 record in users with name "John" and last_name "Wayne" 
  When I stash the fixture as done   
  And I rollback the stashed fixtures
  Then I should see 0 records in users
