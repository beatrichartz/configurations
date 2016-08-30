module Configurations
  module Maps
    class Blocks
      class Entry
        attr_reader :block

        def initialize(block)
          @block = block
        end

        def evaluate!(value)
          return value unless @block
          block.call(value)
        end
      end

      def initialize(reader = Readers::Tolerant.new)
        @map = {}
        @reader = reader
        @default = nil
      end

      def add_default(block)
        @default = Entry.new(block)
      end

      def add(block, properties)
        properties.each do |property|
          add_entry(property, block, @map)
        end
      end

      def entries_at(path)
        entries = @reader.read(@map, path) || {}
        entries.dup.keep_if { |_, v| v.is_a?(Entry) }
      end

      def evaluate!(path, value)
        entry = @reader.read(@map, path) || @default
        return unless entry

        entry.evaluate!(value)
      end

      def add_entry(property, block, subtree)
        if property.is_a?(Hash)
          property.each do |key, val|
            subtree[key] = add_entry(val, block, subtree.fetch(key, {}))
          end
        elsif property.is_a?(Array)
          property.each do |val|
            add_entry(val, block, subtree)
          end
        else
          subtree[property] = Entry.new(block)
        end

        subtree
      end
    end
  end
end
