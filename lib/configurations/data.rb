module Configurations
  # Configuration is a blank object in order to allow configuration
  # of various properties including keywords
  #
  class Data
    def initialize(
      data,
      reserved_method_validator = Validators::ReservedMethods.new
    )
      @data = data
      @reserved_method_validator = reserved_method_validator
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @reserved_method_validator.validate!(key)

      @data[key] = value
    end

    def key?(key)
      @data.key?(key)
    end

    def fetch(key, &block)
      @data.fetch(key, &block)
    end

    def each(&block)
      @data.each(&block)
    end

    def reduce(acc, &block)
      @data.reduce(acc, &block)
    end

    def inspect
      @data.inspect
    end
  end
end
