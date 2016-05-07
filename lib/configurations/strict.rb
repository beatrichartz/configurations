# -*- coding: utf-8 -*-
module Configurations
  # StrictConfiguration is a blank object with setters and getters defined
  # according to the configurable settings given
  #
  module Strict
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
      @reserved_method_tester = ReservedMethodTester.new

      @__configurable__   = options.fetch(:configurable)
      @__configurable_type_map__ = options.fetch(:configurable_type_map)
      @__configurable_block_map__ = options.fetch(:configurable_block_map)
      @configurable_tester = StrictConfigurableTester.new(@__configurable__)
      __evaluate_configurable!

      super
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

    # Add a property to a nested configurable
    #
    def __add_to_nested_configurables!(property, nested, assertion)
      @__nested_configurables__ ||= ::Hash.new { |h, k| h[k] = {} }
      @__nested_configurables__[property].merge!(
        __configurable_hash__(property, nested, assertion)
      )
    end

    # Get an options hash for a property
    #
    def __options_hash_for__(property)
      nested_path = @__path__.add(property)
      super(property).merge(
        configurable: @__nested_configurables__[property],
        configurable_type_map: @__configurable_type_map__,
        configurable_block_map: @__configurable_block_map__,
        path: nested_path)
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
      @reserved_method_tester.test_reserved!(property)
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
        @data.fetch(property) do
          @__not_configured_block_map__.evaluate!(@__path__.add(property), property)
          if @__not_configured_default_callback__
            @__not_configured_default_callback__.call(property)
          end
        end
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
      @__configurable_type_map__.test!(@__path__.add(property), value)
      v = @__configurable_block_map__.evaluate!(@__path__.add(property), value)

      value = v unless v.nil?
      super(property, value)
    end
  end
end
