module Configurations
  # Configuration is a blank object in order to allow configuration of various properties including keywords
  #
  class Configuration < BasicObject

    # 1.9 does not allow for method rebinding in another scope
    #
    if ::RUBY_VERSION < '2.0.0'
      include ::Kernel
      undef :nil?, :===, :=~, :!~, :eql?, :hash, :<=>, :class, :singleton_class, :clone, :dup, :initialize_dup,
            :initialize_clone, :taint, :tainted?, :untaint, :untrust, :untrusted?, :trust, :freeze, :frozen?,
            :to_s, :inspect, :methods, :singleton_methods, :protected_methods, :private_methods, :public_methods,
            :instance_variables, :instance_variable_get, :instance_variable_set, :instance_variable_defined?,
            :instance_of?, :kind_of?, :tap, :send, :public_send, :respond_to?, :respond_to_missing?, :extend,
            :display, :method, :public_method, :define_singleton_method, :to_enum, :enum_for
    else
      # @!macro [attach] install_kernel_method
      # @method $1
      #
      def self.install_kernel_method(method)
        kernel_method = ::Kernel.instance_method(method)

        define_method method do |*args, &block|
          kernel_method.bind(self).call(*args, &block)
        end
      end

      # Installs the type asserting is_a? method from Kernel
      #
      install_kernel_method(:is_a?)

      # Installs the inspect method from Kernel
      #
      install_kernel_method(:inspect)
    end

    # Initialize a new configuration
    # @param [Proc] configuration_defaults A proc yielding to a default configuration
    # @param [Hash] configurable a hash of configurable properties and their asserted types if given
    # @param [Proc] block a block to configure this configuration with
    # @return [HostModule::Configuration] a configuration
    #
    def initialize(configuration_defaults, configurable, &block)
      @_writeable = true
      @configurable = configurable
      @configuration = _configuration_hash

      _evaluate_configurable!

      self.instance_eval(&configuration_defaults) if configuration_defaults

      if block
        self.instance_eval(&block)
        self._writeable = false
      end
    end

    # Method missing gives access for reading and writing to the underlying configuration hash via dot notation
    #
    def method_missing(method, *args, &block)
      property = method.to_s[0..-2].to_sym

      if _is_writer?(method) && _configurable?(property)
        _assert_type!(property, args.first)
        @configuration[property] = args.first
      elsif !_is_writer?(method) && @_writeable || _configured?(method)
        @configuration[method]
      else
        super
      end
    end

    # Respond to missing according to the method_missing implementation
    #
    def respond_to_missing?(method, include_private = false)
      is_setter?(method) || @_writeable || _configured?(method) || super
    end

    # Set the configuration to writeable or read only. Access to writer methods is only allowed within the
    # configure block, this method is used to invoke writability for subconfigurations.
    # @param [Boolean] data true if the configuration should be writeable, false otherwise
    #
    def _writeable=(data)
      @_writeable = data
      @configuration.each do |k,v|
        v._writeable = data if v.is_a?(Configuration)
      end
    end

    # A convenience accessor to get a hash representation of the current state of the configuration
    # @return [Hash] the configuration in hash form
    #
    def to_h
      @configuration.inject({}) do |h, (k,v)|
        h[k] = v.is_a?(Configuration) ? v.to_h : v

        h
      end
    end

    private

    # @param [Symbol] property The property to test for configurability
    # @return [Boolean] whether the given property is configurable
    #
    def _configurable?(property)
      _arbitrarily_configurable? or @configurable.has_key?(property)
    end

    # @param [Symbol] property The property to test for
    # @return [Boolean] whether the given property has been configured
    #
    def _configured?(property)
      @configuration.has_key?(property)
    end

    # @return [Hash] A configuration hash instantiating subhashes if the key is configurable
    #
    def _configuration_hash
      ::Hash.new do |h, k|
        h[k] = Configuration.new(nil, @configurable) if _configurable?(k)
      end
    end

    # Evaluates configurable properties and passes eventual hashes down to subconfigurations
    #
    def _evaluate_configurable!
      return if _arbitrarily_configurable?

      @configurable.each do |k, type|
        if k.is_a?(::Hash)
          k.each do |property, nested|
            @configuration[property] = Configuration.new(nil, _to_configurable_hash(nested, type))
          end
        end
      end
    end

    # @param [Symbol, Hash, Array] value configurable properties, either single or nested
    # @param [Class] type the type to assert, if any
    # @return a hash with configurable values pointing to their types
    #
    def _to_configurable_hash(value, type)
      value = [value] unless value.is_a?(::Array)
      ::Hash[value.zip([type].flatten*value.size)]
    end

    # Type assertion for configurable properties
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    # @raise [ConfigurationError] if the given value has the wrong type
    #
    def _assert_type!(property, value)
      return if _arbitrarily_configurable?

      expected_type = @configurable[property]
      return if expected_type.nil?

      ::Kernel.raise ConfigurationError, "Expected #{property} to be configured with #{expected_type}, but got #{value.class.inspect}", caller unless value.is_a?(expected_type)
    end

    # @return [Boolean] whether this configuration is arbitrarily configurable
    #
    def _arbitrarily_configurable?
      @configurable.nil? or @configurable.empty?
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the given method is a writer
    #
    def _is_writer?(method)
      method.to_s.end_with?('=')
    end

  end
end
