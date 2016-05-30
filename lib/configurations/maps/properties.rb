module Configurations
  module Maps
    class Properties
      attr_reader :map
      class Entry
      end

      def initialize(reader = Readers::Tolerant.new)
        @map = {}
        @reader = reader
      end

      def empty?
        @map.empty?
      end

      def add(properties)
        properties.each do |property|
          add_entry(property, @map)
        end
      end

      def entries_at(path)
        @reader.read(@map, path) || {}
      end

      def configurable?(path)
        !!@reader.read(@map, path)
      end

      def add_entry(property, subtree)
        if property.is_a?(Hash)
          property.each do |key, val|
            subtree[key] = add_entry(val, subtree.fetch(key, {}))
          end
        elsif property.is_a?(Array)
          property.each do |val|
            add_entry(val, subtree)
          end
        else
          subtree[property] = Entry.new
        end

        subtree
      end
    end
  end
end
