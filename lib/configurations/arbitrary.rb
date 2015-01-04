# coding: utf-8
module Configurations
  # Configuration is a blank object in order to allow configuration of various properties including keywords
  #
  class ArbitraryConfiguration < Configuration

    def initialize(options={}, &block)
      self.__writeable__ = true
      super
      self.__writeable__ = false if block
    end

    # Method missing gives access for reading and writing to the underlying configuration hash via dot notation
    #
    def method_missing(method, *args, &block)
      if __respond_to_writer?(method)
        __assign!(method.to_s[0..-2].to_sym, args.first)
      elsif __respond_to_method_for_write?(method)
        @data[method]
      elsif __respond_to_method_for_read?(method, *args, &block)
        @data.fetch(method, &__not_configured_callback_for__(method))
      else
        super
      end
    end

    # Respond to missing according to the method_missing implementation
    #
    def respond_to_missing?(method, include_private = false)
      __respond_to_writer?(method) ||  __respond_to_method_for_read?(method, *args, &block) || __respond_to_method_for_write?(method) || super
    end

    # A convenience accessor to instantiate a configuration from a hash
    # @param [Hash] h the hash to read into the configuration
    # @return [Configuration] the configuration with values assigned
    # @note can only be accessed during writeable state (in configure block). Unassignable values are ignored
    #
    def from_h(h)
      raise ArgumentError, 'can not dynamically assign values from a hash' unless @__writeable__
      super
    end

    # @param [Symbol] property The property to test for configurability
    # @return [Boolean] whether the given property is configurable
    #
    def __configurable?(property)
      true
    end

    # Set the configuration to writeable or read only. Access to writer methods is only allowed within the
    # configure block, this method is used to invoke writability for subconfigurations.
    # @param [Boolean] data true if the configuration should be writeable, false otherwise
    #
    def __writeable__=(data)
      @__writeable__ = data
      return unless @data

      @data.each do |k,v|
        v.__writeable__ = data if v.is_a?(__class__)
      end
    end

    private

    # @param [Symbol] property The property to test for
    # @return [Boolean] whether the given property has been configured
    #
    def __configured?(property)
      true
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the given method is a writer
    #
    def __is_writer?(method)
      method.to_s.end_with?('=')
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the configuration responds to the given property as a method during writeable state
    #
    def __respond_to_method_for_write?(method)
      !__is_writer?(method) && @__writeable__ && @data[method].is_a?(__class__)
    end

    def __respond_to_method_for_read?(method, *args, &block)
      !__is_writer?(method) && args.empty? && block.nil?
    end

    def __respond_to_writer?(method)
      @__writeable__ && __is_writer?(method)
    end

  end
end
