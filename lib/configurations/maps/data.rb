module Configurations
  module Maps
    class Data
      class Entry
        def initialize(value)
          @value = value
        end
      end

      def initialize(
        reader = Readers::Tolerant.new,
        writer = Writers::Default.new { |value|
          Entry.new(value)
        }
      )
        @map = {}
        @reader = reader
        @writer = writer
      end

      def nested?(path)
        @reader.read(@map, path)
      end

      def add_entry(path, value)
        @writer.write(@map, path, value)
      end
    end
  end
end
