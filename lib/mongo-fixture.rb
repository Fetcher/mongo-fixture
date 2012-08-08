# Third-party
require "fast/fast"
require "symbolmatrix"

require "mongo-fixture/version"

module Mongo

  # Fixture managing class for MongoDB
  class Fixture
    ## Class methods
    
    # Returns the current path to the fixtures folder
    def self.path
      @@path ||= "test/fixtures"
    end

    ## Instance methods
    
    # Initializes the fixture handler
    # Accepts optionally a symbol as a reference to the fixture
    # and a Mongo::DB connection
    def initialize fixture = nil, connection = nil, option_push = true
      load fixture if fixture
      
      @connection = connection if connection
      push if fixture && connection && option_push
    end    
    
    # Loads the fixture files into this instance
    def load fixture
      raise LoadingFixtureIllegal, "A check has already been made, loading a different fixture is illegal" if @checked
      
      Fast.dir("#{fixtures_path}/#{fixture}").files.to.symbols.each do |file|
        @data ||= {}
        @data[file] = SymbolMatrix.new "#{fixtures_path}/#{fixture}/#{file}.yaml"
      end
    end
        
    # Returns the current fixtures path where Sequel::Fixtures looks for fixture folders
    def fixtures_path
      Mongo::Fixture.path
    end    
    
    # Assures that the collections are empty before proceeding
    def check
      return @checked if @checked # If already checked, it's alright

      raise MissingFixtureError, "No fixture has been loaded, nothing to check" unless @data
      raise MissingConnectionError, "No connection has been provided, impossible to check" unless @connection
      
      @data.each_key do |collection|
        if @connection[collection].count != 0
          raise CollectionsNotEmptyError, "The collection '#{collection}' is not empty, all collections should be empty prior to testing" 
        end
      end
      return @checked = true
    end
  end
end
