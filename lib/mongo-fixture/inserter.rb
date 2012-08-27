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
      def simplify the_record
        the_returned_hash = {}
        the_record.each do |field, value|
          begin
            value = resolve_field_hash value if value.is_a? Hash
          rescue Mongo::Fixture::ReferencedRecordNotFoundError => e
            @fixture.rollback
            raise e
          end
          the_returned_hash[field] = value
        end
        return the_returned_hash
      end

      # Returns the correct data for this field resolving the hash
      def resolve_field_hash value
        raise ArgumentError, "Hash expected" unless value.is_a? Hash
        return value[:processed] if value.has_key? :processed

        intersection = value.keys & @fixture.data.keys
        if intersection.empty?
          raise Mongo::Fixture::ReferencedRecordNotFoundError,
            "This fixture does not include data for the collections [#{value.keys.join(',')}]"
        else
          intersection.each do |collection|
            insert_data_for collection unless data_was_inserted_in? collection
            if value[collection].is_a? Array
              ids = []
              value[collection].each do |element|
                ids.push do_the_resolving collection, element.to_sym
              end
              return ids
            else
              return do_the_resolving collection, value[collection].to_sym
            end
          end
        end
      end

#            options = value.keys & @fixture.data.keys
#            # If no alternative matches the name of a collection, look for a :processed value
#            if options.empty?
#              unless value.has_key? :processed
#                raise MissingProcessedValueError.new "The processed value to insert into the db is missing from the field '#{field}', aborting", field 
#              end
#              the_returned_hash[field] = value[:processed]
#            else
#            
#              # Does any of the options hold a record named after the value of the option?
#              actual_option = options.each do |option|
#                break option if @fixture.data[option].has_key? value[option].to_sym
#              end
#              
#              unless data_was_inserted_in? actual_option
#                insert_data_for actual_option
#              end
#              current_collection = @connection[actual_option]
#              current_data = simplify @fixture.data[actual_option][value[actual_option].to_sym]
#              the_returned_hash[field] = current_collection.find(current_data).first["_id"]
#            end


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
        return if data_was_inserted_in? collection
        @fixture.data[collection].each do |key, record|
          begin
            @fixture.connection[collection].insert simplify record
          rescue MissingProcessedValueError => m
            @fixture.rollback
            raise MissingProcessedValueError, "In record '#{key}' to be inserted into '#{collection}', the processed value of field '#{m.field}' is missing, aborting"
          end
        end
        @inserted << collection
      end

      # Returns true if the collection was already inserted
      def data_was_inserted_in? collection
        @inserted.include? collection
      end      

      def inserted
        @inserted
      end

      # Returns the fixture
      attr_reader :fixture

      private
        def validate_record_existence collection, record_name
          unless @fixture.data[collection].has_key? record_name
            raise Mongo::Fixture::ReferencedRecordNotFoundError,
              "The collection '#{collection}' doesn't include the record '#{record_name}'"
          end
        end

        def do_the_resolving collection, record_name
          validate_record_existence collection, record_name

          record_data = simplify @fixture.data[collection][record_name]
          return @fixture.connection[collection].find(record_data).first["_id"]
        end
    end
  end
end
