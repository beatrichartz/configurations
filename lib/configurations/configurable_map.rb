module Configurations
  class ConfigurableMap
    attr_reader :map
    class Entry
      attr_reader :block
      attr_reader :type

      def initialize(type, block)
        @type = type
        @block = block
      end

      def valid?(value)
        !@type || value.is_a?(@type)
      end
    end

    def initialize
      @map = {}
    end

    def add(type, properties, block)
      properties.each do |property|
        add_entry(property, type, block, @map)
      end
    end

    def test!(path, value)
      entry = path.walk(@map)
      return unless entry

      fail(
        ConfigurationError,
        "#{path.print} must be configured with #{entry.type} (got #{value})",
        caller
      ) unless entry.valid?(value)
    end

    def add_entry(property, type, block, subtree)
      if property.is_a?(Hash)
        property.each do |key, val|
          subtree[key] = add_entry(val, type, block, subtree.fetch(key, {}))
        end
      elsif property.is_a?(Array)
        property.each do |val|
          add_entry(val, type, block, subtree)
        end
      else
        subtree[property] = Entry.new(type, block)
      end

      subtree
    end
  end
end
