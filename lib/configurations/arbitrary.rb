# coding: utf-8
module Configurations
  # Configuration is a blank object in order to allow configuration of
  # various properties including keywords
  #
  module Arbitrary
    # Initialize a new configuration
    # @param [Hash] options The options to initialize a configuration with
    # @option options [Hash] methods a hash of method names pointing to procs
    # @option options [Proc] not_configured a proc to evaluate for
    #   not_configured properties
    # @param [Proc] block a block to configure this configuration with
    # @yield [HostModule::Configuration] a configuration
    # @return [HostModule::Configuration] a configuration
    # @note An arbitrary configuration has to control its writeable state,
    #   therefore configuration is only possible in the initialization block
    #
    def initialize(options = {}, &block)
      self.__writeable__ = true
      super
      self.__writeable__ = false if block
    end

    # Method missing gives access for reading and writing to the underlying
    # configuration hash via dot notation
    #
    def method_missing(method, *args, &block)
      if __respond_to_writer?(method)
        __assign!(method.to_s[0..-2].to_sym, args.first)
      elsif __respond_to_method_for_write?(method)
        @data[method]
      elsif __respond_to_method_for_read?(method, *args, &block)
        @data.fetch(method) do
          @not_configured_blocks.evaluate!(@path.add(method), method)
        end
      else
        super
      end
    end

    # Respond to missing according to the method_missing implementation
    #
    def respond_to_missing?(method, include_private = false)
      __respond_to_writer?(method) ||
        __respond_to_method_for_read?(method, *args, &block) ||
        __respond_to_method_for_write?(method) ||
        super
    end

    # A convenience accessor to instantiate a configuration from a hash
    # @param [Hash] h the hash to read into the configuration
    # @return [Configuration] the configuration with values assigned
    # @note can only be accessed during writeable state (in configure block).
    #   Unassignable values are ignored
    # @raise [ArgumentError] unless used in writeable state
    #   (in configure block)
    #
    def from_h(h)
      unless @writeable
        fail ::ArgumentError, 'can not dynamically assign values from a hash'
      end

      super
    end

    # Set the configuration to writeable or read only. Access to writer methods
    # is only allowed within the configure block, this method is used to invoke
    # writeability for subconfigurations.
    # @param [Boolean] data true if the configuration should be writeable,
    #   false otherwise
    #
    def __writeable__=(data)
      @writeable = data
      return unless defined?(@data) && @data

      @data.each do |_k, v|
        v.__writeable__ = data if v.is_a?(__class__)
      end
    end

    private

    # @param [Symbol] property The property to test for
    # @return [Boolean] whether the given property has been configured
    #
    def __configured?(_property)
      true
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the given method is a writer
    #
    def __is_writer?(method)
      method.to_s.end_with?('=')
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the configuration responds to the given
    #   property as a method during writeable state
    #
    def __respond_to_method_for_write?(method)
      !__is_writer?(method) && @writeable && @data[method].is_a?(__class__)
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the configuration responds to the
    #   given property
    #
    def __respond_to_method_for_read?(method, *args, &block)
      !__is_writer?(method) && args.empty? && block.nil?
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the method is a writer and is used in writeable
    #   state
    #
    def __respond_to_writer?(method)
      @writeable && __is_writer?(method)
    end
  end
end
