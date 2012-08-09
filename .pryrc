require "mongo-fixture"
DB = Mongo::Connection.new.db "mongo-fixture-cucumber"
puts "\e[34mConnection to MongoDB 'mongo-fixture-cucumber' loaded in \e[1mDB\e[0m\e[34m variable\e[0m"
puts "\e[34mTry the \e[1mDB[:visitors]\e[0m\e[34m, \e[1mDB[:aliens]\e[0m\e[34m, \e[1mDB[:visits]\e[0m\e[34m and \e[1mDB[:users]\e[0m\e[34m collections\e[0m"
@DB = DB
def self.drop *args
  args.each do |coll|
    @DB[coll].drop
  end
end

puts "\e[34mTip: for fast collection dropping use \e[1mdrop :collection1, :collection2\e[0m"
