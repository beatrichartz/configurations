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
      @reserved_method_validator = Validators::ReservedMethods.new

      @path       = options.fetch(:path) { Path.new }
      @properties = options.fetch(:properties) { Maps::Properties.new }
      @types      = options.fetch(:types)
      @blocks     = options.fetch(:blocks)

      __evaluate_configurable!

      super
    end

    private

    # Evaluates configurable properties and passes eventual hashes
    # down to subconfigurations
    #
    def __evaluate_configurable!
      entries = @properties.entries_at(@path)
      entries.each do |property, value|
        if value.is_a?(Maps::Properties::Entry)
          __install_property__(property)
        else
          __install_nested_getter__(property)
        end
      end
    end

    # Get an options hash for a property
    #
    def __options_hash_for__(property)
      _nested_path = @path.add(property)
      super(property).merge(
        properties: @properties,
        types: @types,
        blocks: @blocks
      )
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
      @reserved_method_validator.validate!(property)
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
          @not_configured_blocks.evaluate!(@path.add(property), property)
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
      @types.test!(@path.add(property), value)
      v = @blocks.evaluate!(@path.add(property), value)

      value = v unless v.nil?
      super(property, value)
    end
  end
end
