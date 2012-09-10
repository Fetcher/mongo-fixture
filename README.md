Mongo::Fixture
===============
[![Build Status](https://secure.travis-ci.org/Fetcher/mongo-fixture.png)](http://travis-ci.org/Fetcher/mongo-fixture) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/Fetcher/mongo-fixture)

Similar to Rails 2 fixtures, but for [MongoDB][mongo-db] (using the standard [mongo connector Gem][mongo-gem] ).

[mongo-db]: http://www.mongodb.org/
[mongo-gem]: http://rubygems.org/gems/mongo

Show off
========

### Single collection 

Assuming you have a fixture for the collection `messages` with:
```yaml
# test/fixtures/some_data/messages.yaml
yesterday_afternoon:
  text: Honey, pizza tonight?
  sent: 2012-09-11
today_morning:
  text: Nice date yesterday, how about next week?
  sent: 2012-09-12
```

You can write a brief ruby script and insert the data into your mongo db:
```
require 'mongo'
require 'mongo-fixture'

DB = Mongo::Connection.new.db 'messages-db' # An example connetion setup

# Insert the fixture into the database
fixture_some_data = Mongo::Fixture.new :some_data, DB

# You can now query the fixture for the data that was sent into the DB
fixture_some_data.messages.yesterday_afternoon.text # => "Honey, pizza tonight?"
```

The fixture is identified by the name of the folder containing the fixture YAML files. The default folder is `test/fixtures`.

As you can see, each record is preceded by a name, in this case `yesterday_afternoon` and `today_morning`. This names never get inserted into the database, they are just references for making it easier to access the fixture's information.

### Associations

Assuming you have a fixture for the collection users with:
```yaml
# test/fixtures/simple/users.yaml
john:
  name: John
  last_name: Doe
  email: john@doe.com
jane:
  name: Jane
  last_name: Doe
  email: jane@doe.com
```

and for messages:
```yaml
# test/fixtures/simple/messages.yaml
greeting:
  sender:
    users: john
  receiver:
    users: jane
  text: Hi Jane! Long time no see.
long_time:
  sender:
    users: jane
  receiver:
    users: john
  text: John! Long time indeed. How are you doing?
```

Mongo Fixture will automatically insert the object id (`_id` field in the database) for the referenced users. The Mongo Fixture syntax specifies that:

```yaml
  sender:
    users: john
```

is a reference to the record named `john` in the collection `users`.

> Currently Mongo Fixture does not support references from one collection to another _and back_ from that collection to the first one.

For example given the ruby script:

```ruby
# script.rb
require "mongo-fixture"

DB = Mongo::Connection.new.db 'mongo-test-db' # Just a simple example

fixture = Mongo::Fixture.new :simple, DB # Will load all the data in the fixture into the database

fixture.users               # == fixture[:users]
fixture.users.john.name     # => "John"
                            # The YAML files are parsed into a SymbolMatrix
                            # http://github.com/Fetcher/symbolmatrix

fixture.rollback            # returns users and messages to pristine status (#drop)


fixture = Mongo::Fixture.new :simple, DB, false    # The `false` flag prevent the constructor to automatically push
                                                   # the fixture into the database
                                                    
fixture.check               # Will fail if the user or messages collection
                            # were already occupied with something
                            
fixture.push                # Inserts the fixture in the database

fixture.rollback            # Don't forget to rollback

```

...naturally, `mongo-fixture` makes a lot more sense within some testing framework.

### Many to many associations

As is custom in Mongo, a many-to-many association is implemented by passing an array of ids to a field in any of the records to associate. Mongo Fixture supports this. For example:

```yaml
message:
  sender:
    users: john
  receivers:
    users: [mary, sue, harry, jack]
  text: Meeting tonight guys?
```

will insert into the `receivers` field an array with the `_id`s of the referenced users.

> **Note**: As of version 0.0.5, the `test/fixtures` path for fixtures is _still_ not configurable. Will solve soon.

Installation
------------

    gem install mongo-fixture

### Or using Bundler

    gem 'mongo-fixture'

And then execute:

    bundle


## License

Copyright (C) 2012 Fetcher

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
