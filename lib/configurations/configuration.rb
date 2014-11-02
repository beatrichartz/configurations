# -*- coding: utf-8 -*-
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
      # @macro [attach] install_kernel_method
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
    def initialize(configuration_defaults, configurable, defaults_to_nil, &block)
      @_writeable = true
      @configurable = configurable
      @configuration = _configuration_hash
      @defaults_to_nil = defaults_to_nil

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
      value = args.first

      if _respond_to_writer?(method)
        _assign!(property, value)
      elsif _respond_to_property?(method)
        @configuration[method]
      elsif _can_delegate_to_kernel?(method)
        ::Kernel.send(method, *args, &block)
      else
        defaults_to_nil ? nil : super
      end
    end

    attr_reader :defaults_to_nil

    # Respond to missing according to the method_missing implementation
    #
    def respond_to?(method, include_private = false)
      _respond_to_writer?(method) or _respond_to_property?(method) or _can_delegate_to_kernel?(method) or super
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

    # A convenience accessor to instantiate a configuration from a hash
    # @param [Hash] h the hash to read into the configuration
    # @return [Configuration] the configuration with values assigned
    # @note can only be accessed during writeable state (in configure block). Unassignable values are ignored
    #
    def from_h(h)
      raise ArgumentError, 'can not dynamically assign values from a hash' unless @_writeable

      h.each do |property, value|
        if value.is_a?(::Hash) && _nested?(property)
          @configuration[property].from_h(value)
        elsif _configurable?(property)
          _assign!(property, value)
        end
      end
    end

    # @param [Symbol] property The property to test for configurability
    # @return [Boolean] whether the given property is configurable
    #
    def _configurable?(property)
      _arbitrarily_configurable? or @configurable.has_key?(property)
    end


    # @return [Boolean] whether this configuration is arbitrarily configurable
    #
    def _arbitrarily_configurable?
      @configurable.nil? or @configurable.empty?
    end

    # @return [Hash] the configurations configurable hash
    def _configurable
      @configurable
    end

    private

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
        h[k] = Configuration.new(nil, @configurable, @defaults_to_nil) if _configurable?(k)
      end
    end

    # Evaluates configurable properties and passes eventual hashes down to subconfigurations
    #
    def _evaluate_configurable!
      return if _arbitrarily_configurable?

      @configurable.each do |k, assertion|
        if k.is_a?(::Hash)
          k.each do |property, nested|
            @configuration[property] = Configuration.new(nil, _configurable_hash(property, nested, assertion), @defaults_to_nil)
          end
        end
      end
    end

    # @param [Symbol, Hash, Array] property configurable properties, either single or nested
    # @param [Symbol, Hash, Array] value configurable properties, either single or nested
    # @param [Hash] assertion assertion if any
    # @return a hash with configurable values pointing to their types
    #
    def _configurable_hash(property, value, assertion)
      value = [value] unless value.is_a?(::Array)
      hash  = ::Hash[value.zip([assertion].flatten*value.size)]
      hash  = @configuration[property]._configurable.merge(hash) if @configuration.has_key?(property)

      hash
    end

    # Assigns a value after running the assertions
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    #
    def _assign!(property, value)
      _assert_type!(property, value)
      v = _evaluate_block!(property, value)
      value = v unless v.nil?
      @configuration[property] = value
    end

    # Type assertion for configurable properties
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    # @raise [ConfigurationError] if the given value has the wrong type
    #
    def _assert_type!(property, value)
      return unless _evaluable?(property, :type)

      assertion = @configurable[property][:type]
      ::Kernel.raise ConfigurationError, "Expected #{property} to be configured with #{assertion}, but got #{value.class.inspect}", caller unless value.is_a?(assertion)
    end

    # Block assertion for configurable properties
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    #
    def _evaluate_block!(property, value)
      return value unless _evaluable?(property, :block)

      evaluation = @configurable[property][:block]
      evaluation.call(value)
    end

    # @param [Symbol] property The property to test for
    # @param [Symbol] assertion_type The evaluation type type to test for
    # @return [Boolean] whether the given property is assertable
    #
    def _evaluable?(property, evaluation)
      @configurable and @configurable.has_key?(property) and @configurable[property].is_a?(::Hash) and @configurable[property].has_key?(evaluation)
    end

    # @param [Symbol] property The property to test for
    # @return [Boolean] whether this property is nested
    #
    def _nested?(property)
      _arbitrarily_configurable? or @configuration.has_key?(property) and @configuration[property].is_a?(Configuration)
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the given method is a writer
    #
    def _is_writer?(method)
      method.to_s.end_with?('=')
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the configuration responds to the given method writer
    #
    def _respond_to_writer?(method)
      _is_writer?(method) and @_writeable and _configurable?(_property_from_writer(method))
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the configuration responds to the given property as a method
    #
    def _respond_to_property?(method)
      not _is_writer?(method) and (@_writeable or _configured?(method))
    end

    # @param [Symbol] method the method to test for
    # @return [Boolean] whether the configuration can delegate the given method to Kernel
    #
    def _can_delegate_to_kernel?(method)
      ::Kernel.respond_to?(method, true)
    end

    # @param [Symbol] method the writer method to turn into a property
    # @return [Symbol] the property derived from the writer method
    #
    def _property_from_writer(method)
      method.to_s[0..-2].to_sym
    end

  end
end
