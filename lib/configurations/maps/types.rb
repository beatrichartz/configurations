module Configurations
  module Maps
    class Types
      attr_reader :map
      class Entry
        attr_reader :type

        def initialize(type)
          @type = type
        end

        def valid?(value)
          !@type || value.is_a?(@type)
        end
      end

      def initialize(reader = Readers::Tolerant.new)
        @map = {}
        @reader = reader
      end

      def add(type, properties)
        properties.each do |property|
          add_entry(property, type, @map)
        end
      end

      def test!(path, value)
        entry = @reader.read(@map, path)
        return unless entry

        fail(
          ConfigurationError,
          "#{path.print} must be configured with #{entry.type} (got #{value})",
          caller
        ) unless entry.valid?(value)
      end

      def add_entry(property, type, subtree)
        if property.is_a?(Hash)
          property.each do |key, val|
            subtree[key] = add_entry(val, type, subtree.fetch(key, {}))
          end
        elsif property.is_a?(Array)
          property.each do |val|
            add_entry(val, type, subtree)
          end
        else
          subtree[property] = Entry.new(type)
        end

        subtree
      end
    end
  end
end
