module Configurations
  # Configuration is a blank object in order to allow configuration of various properties including keywords
  #
  class Configuration < BlankObject

    # Initialize a new configuration
    # @param [Hash] options The options to initialize a configuration with
    # @option options [Hash] configurable a hash of configurable properties and their asserted types if given
    # @option options [Hash] methods a hash of method names pointing to procs
    # @option options [Proc] not_configured a proc to evaluate for not_configured properties
    # @param [Proc] block a block to configure this configuration with
    # @yield [HostModule::Configuration] a configuration
    # @return [HostModule::Configuration] a configuration
    #
    def initialize(options={}, &block)
      @__methods__ = options.fetch(:methods) { ::Hash.new }
      @__not_configured__ = options.fetch(:not_configured) { ::Hash.new }

      @data = __configuration_hash__

      __instance_eval__(&options[:defaults]) if options[:defaults]
      __instance_eval__(&block) if block

      __install_configuration_methods__
    end

    # Method missing gives access for reading and writing to the underlying configuration hash via dot notation
    #
    def method_missing(method, *args, &block)
      if __can_delegate_to_kernel?(method)
        ::Kernel.__send__(method, *args, &block)
      else
        super
      end
    end

    # Respond to missing according to the method_missing implementation
    #
    def respond_to_missing?(method, include_private = false)
      __can_delegate_to_kernel?(method) || super
    end

    # A convenience accessor to get a hash representation of the current state of the configuration
    # @return [Hash] the configuration in hash form
    #
    def to_h
      @data.inject({}) do |h, (k,v)|
        h[k] = v.is_a?(__class__) ? v.to_h : v

        h
      end
    end

    # A convenience accessor to instantiate a configuration from a hash
    # @param [Hash] h the hash to read into the configuration
    # @return [Configuration] the configuration with values assigned
    # @note can only be accessed during writeable state (in configure block). Unassignable values are ignored
    #
    def from_h(h)
      h.each do |property, value|
        if value.is_a?(::Hash) && __nested?(property)
          @data[property].from_h(value)
        elsif __configurable?(property)
          __assign!(property, value)
        end
      end
    end

    # @param [Symbol] property The property to test for configurability
    # @return [Boolean] whether the given property is configurable
    #
    def __configurable?(property)
      raise NotImplementedError, 'must be implemented in subclass'
    end

    # @param [Symbol] property The property to test for
    # @return [Boolean] whether the given property has been configured
    #
    def __configured?(property)
      @data.key?(property)
    end

    def __empty?
      @data.empty?
    end

    protected

    def __install_configuration_methods__
      @__methods__.each do |meth, block|
        __define_singleton_method__(meth, &block)
      end
    end

    def __options_hash_for__(property)
      hash = {}
      hash[:not_configured] = @__not_configured__[property] if @__not_configured__[property]
      hash[:methods] = @__methods__[property] if @__methods__.key?(property)

      hash
    end

    def __not_configured_callback_for__(property)
      @__not_configured__[property] || ::Proc.new{ nil }
    end

    # @return [Hash] A configuration hash instantiating subhashes if the key is configurable
    #
    def __configuration_hash__
      ::Hash.new do |h, k|
        h[k] = __class__.new(__options_hash_for__(k)) if __configurable?(k)
      end
    end

    # Assigns a value after running the assertions
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    #
    def __assign!(property, value)
      @data[property] = value
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the given method is a writer
    #
    def __is_writer?(method)
      method.to_s.end_with?('=')
    end

    def __nested?(property)
      @data[property].is_a?(__class__)
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the configuration can delegate the given method to Kernel
    #
    def __can_delegate_to_kernel?(method)
      ::Kernel.respond_to?(method, true)
    end

    # @param [Symbol] method the writer method to turn into a property
    # @return [Symbol] the property derived from the writer method
    #
    def __property_from_writer__(method)
      method.to_s[0..-2].to_sym
    end

  end
end
