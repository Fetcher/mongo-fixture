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

Scenario: References across collections
  Given a collection users
  And a collection sessions
  And a file "test/fixtures/references/users.yaml" with:
    """
    pepe:
      username: pepe
      password: 
        raw: secreto
        processed: 252db48960f032db4bb604bc26f97106fa85ff88dedef3a28671b6bcd9f9644bf90d7e444d587c9351dfa237a6fc8fe38641a8469d084a166c7807d9c6564860
      name: Pepe
    """
  And a file "test/fixtures/references/sessions.yaml" with: 
    """
    14_horas:
      user: 
        users: pepe
      time: 2012-07-30T14:02:40-03:00
    y_tres_minutos:
      user: 
        users: pepe
      time: 2012-07-30T14:03:40-03:00
    y_cuatro_minutos:
      user: 
        users: pepe
      time: 2012-07-30T14:04:40-03:00
    """
  And I load the references fixture
  Then I should see 1 record in users with username "pepe" and name "Pepe"
  And I should see 3 records in sessions

Scenario: Many-to-many associations
  Given a collection users
  And a collection documents
  And a file "test/fixtures/associations/users.yaml" with:
    """
    johnny:
      name: John
      documents:
        documents: [brief, docs, extra_data]
    susan:
      name: Susan
      documents:
        documents: [brief, resume, docs]
    """
  And a file "test/fixtures/associations/documents.yaml" with:
    """
    brief:
      title: Data
      text: Resumee
    docs:
      title: Doc
      text: Documentation
    extra_data:
      title: Xtra
      text: More and more data
    resume:
      title: CV
      text: Curriculum Vitae
    """
  When I load the associations fixture
  Then I should see 2 records in users
  And I should see 3 records in documents
  And the user named "John" should have in documents the id of the one titled "Doc"