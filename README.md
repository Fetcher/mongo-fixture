Mongo::Fixture
===============
[![Build Status](https://secure.travis-ci.org/Fetcher/mongo-fixture.png)](http://travis-ci.org/Fetcher/mongo-fixture) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/Fetcher/mongo-fixture)

Just like Rails 2 fixtures, but for [MongoDB][mongo-db] (using the standard [mongo connector Gem][mongo-gem].

[mongo-db]: http://www.mongodb.org/
[mongo-gem]: http://rubygems.org/gems/mongo

Show off
========

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
  sender_id: 1
  receiver_id: 2
  text: Hi Jane! Long time no see.
long_time:
  sender_id: 2
  receiver_id: 1
  text: John! Long time indeed. How are you doing?
```

and the ruby script

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

> **Note**: As of version 0.0.1, the `test/fixtures` path for fixtures is not configurable. Will solve soon.

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
