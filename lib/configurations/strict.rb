# -*- coding: utf-8 -*-
module Configurations
  # StrictConfiguration is a blank object with setters and getters defined
  # according to the configurable settings given
  #
  class StrictConfiguration < Configuration
    # Initialize a new configuration
    # @param [Hash] options The options to initialize a configuration with
    # @option options [Hash] configurable a hash of configurable properties
    #   and their asserted types if given
    # @option options [Hash] methods a hash of method names pointing to procs
    # @option options [Proc] not_configured a proc to evaluate for
    #   not_configured properties
    # @param [Proc] block a block to configure this configuration with
    # @yield [HostModule::Configuration] a configuration
    # @return [HostModule::Configuration] a configuration
    #
    def initialize(options = {}, &block)
      @__configurable__   = options.fetch(:configurable)
      __evaluate_configurable!

      super
    end

    # @param [Symbol] property The property to test for configurability
    # @return [Boolean] whether the given property is configurable
    #
    def __configurable?(property)
      @__configurable__.key?(property) ||
        @__nested_configurables__.key?(property)
    end

    private

    # Evaluates configurable properties and passes eventual hashes
    # down to subconfigurations
    #
    def __evaluate_configurable!
      @__configurable__.each do |k, assertion|
        if k.is_a?(::Hash)
          k.each do |property, nested|
            __add_to_nested_configurables!(property, nested, assertion)
            __install_nested_getter__(property)
          end
        else
          __install_property__(k)
        end
      end
    end

    def __add_to_nested_configurables!(property, nested, assertion)
      @__nested_configurables__ ||= ::Hash.new { |h, k| h[k] = {} }
      @__nested_configurables__[property].merge!(
        __configurable_hash__(property, nested, assertion)
      )
    end

    def __options_hash_for__(property)
      super(property).merge(configurable: @__nested_configurables__[property])
    end

    # @param [Symbol, Hash, Array] property configurable properties,
    #   either single or nested
    # @param [Symbol, Hash, Array] value configurable properties,
    #   either single or nested
    # @param [Hash] assertion assertion if any
    # @return a hash with configurable values pointing to their types
    #
    def __configurable_hash__(_property, value, assertion)
      value = [value] unless value.is_a?(::Array)
      hash  = ::Hash[value.zip([assertion].flatten * value.size)]

      hash
    end

    # @param [Symbol] property the property to test for
    # @return [Boolean] whether this property is pointing to a
    #   nested configuration
    #
    def __nested?(property)
      respond_to?(property) && __send__(property).is_a?(__class__)
    end

    # Installs a property setter and getter as singleton methods
    # @param [Symbol] property the property to install
    #
    def __install_property__(property)
      __install_setter__(property)
      __install_getter__(property)
    end

    # Installs a property setter as a singleton method
    # @param [Symbol] property the property to install the setter for
    #
    def __install_setter__(property)
      __define_singleton_method__ :"#{property}=" do |value|
        __assign!(property, value)
      end
    end

    # Installs a property getter as a singleton method
    # @param [Symbol] property the property to install the getter for
    #
    def __install_getter__(property)
      __define_singleton_method__ property do
        @data.fetch(property, &__not_configured_callback_for__(property))
      end
    end

    # Installs a property getter for a nested configuration as a
    # singleton method
    # @param [Symbol] property the property to install the getter for
    #
    def __install_nested_getter__(property)
      __define_singleton_method__ property do
        @data[property]
      end
    end

    # Assigns a value after running the assertions
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    #
    def __assign!(property, value)
      __assert_type!(property, value)
      v = __evaluate_block!(property, value)
      value = v unless v.nil?
      super(property, value)
    end

    # Type assertion for configurable properties
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    # @raise [ConfigurationError] if the given value has the wrong type
    #
    def __assert_type!(property, value)
      return unless __evaluable?(property, :type)

      assertion = @__configurable__[property][:type]
      return if value.is_a?(assertion)

      ::Kernel.fail(
        ConfigurationError,
        "#{property} must be configured with #{assertion} (got #{value.class})",
        caller
      )
    end

    # Block assertion for configurable properties
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    #
    def __evaluate_block!(property, value)
      return value unless __evaluable?(property, :block)

      evaluation = @__configurable__[property][:block]
      evaluation.call(value)
    end

    # @param [Symbol] property The property to test for
    # @param [Symbol] assertion_type The evaluation type type to test for
    # @return [Boolean] whether the given property is assertable
    #
    def __evaluable?(property, evaluation)
      __configurable?(property) &&
        @__configurable__[property].is_a?(::Hash) &&
        @__configurable__[property].key?(evaluation)
    end
  end
end
