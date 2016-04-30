module Configurations
  class StrictConfigurableTester

    def initialize(configurable)
      @configurable = configurable
      evaluate_configurable!
    end

    # @param [Symbol] property The property to test for configurability
    # @return [Boolean] whether the given property is configurable
    #
    def configurable?(property)
      @configurable.key?(property) ||
        @nested_configurables.key?(property)
    end

    private

    # Evaluates configurable properties and passes eventual hashes
    # down to subconfigurations
    #
    def evaluate_configurable!
      @configurable.each do |k, assertion|
        if k.is_a?(::Hash)
          k.each do |property, nested|
            add_to_nested_configurables!(property, nested, assertion)
          end
        end
      end
    end

    # Add a property to a nested configurable
    #
    def add_to_nested_configurables!(property, nested, assertion)
      @nested_configurables ||= ::Hash.new { |h, k| h[k] = {} }
      @nested_configurables[property].merge!(
        configurable_hash(property, nested, assertion)
      )
    end

    # @param [Symbol, Hash, Array] property configurable properties,
    #   either single or nested
    # @param [Symbol, Hash, Array] value configurable properties,
    #   either single or nested
    # @param [Hash] assertion assertion if any
    # @return a hash with configurable values pointing to their types
    #
    def configurable_hash(_property, value, assertion)
      value = [value] unless value.is_a?(::Array)
      hash  = ::Hash[value.zip([assertion].flatten * value.size)]

      hash
    end
  end
end
