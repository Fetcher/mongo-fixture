module Mongo
  class Fixture
    # Handles the actual insertion into the database.
    class Inserter

      # Receives a fixture as argument
      def initialize fixture
        @fixture = fixture 
        @inserted = []
      end

      # Simplifies the hash in order to insert it into the database
      # Resolves external references and flattens the values that provide alternatives
      # @param [Hash] the hash to be processed 
      def simplify the_hash
        the_returned_hash = {}
        the_hash.each do |key, value|
          if value.is_a? Hash
            
            # If no alternative matches the name of a collection, look for a :processed value
            if (value.keys && @fixture.data.keys).empty?
              unless value.has_key? :processed
                raise MissingProcessedValueError.new "The processed value to insert into the db is missing from the field '#{key}', aborting", key 
              end
              the_returned_hash[key] = value[:processed]
            else
            
              # Does any of the options hold a record named after the value of the option?
              options = value.keys && @fixture.data.keys
              actual_option = options.each do |option|
                break option if @fixture.data[option].has_key? value[option].to_sym
              end
              
              unless data_was_inserted_in? actual_option
                insert_data_for actual_option
              end
              current_collection = @connection[actual_option]
              current_data = simplify @fixture.data[actual_option][value[actual_option].to_sym]
              the_returned_hash[key] = current_collection.find(current_data).first["_id"]
            end
          else
            the_returned_hash[key] = value
          end
        end
        return the_returned_hash
      end

      # Inserts the collection data into the database
      def insert_data_for collection
#      @data.each do |collection, matrix|
#        unless @inserter.data_was_inserted_in? collection
#          matrix.each do |element, values|
#            begin
#                @connection[collection].insert @inserter.simplify values.to_hash
#            rescue MissingProcessedValueError => m
#              rollback
#              raise MissingProcessedValueError, "In record '#{element}' to be inserted into '#{collection}', the processed value of field '#{m.field}' is missing, aborting"
#            end
#          end
#          @inserted << collection
#        end        
        @fixture.data[collection].each do |key, record|
          @fixture.connection[collection].insert simplify record
        end
        @inserted << collection
      end

      # Returns true if the collection was already inserted
      def data_was_inserted_in? collection
        @inserted.include? collection
      end      
    end
  end
end