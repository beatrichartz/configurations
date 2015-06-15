module Configurations
  # Configuration is a blank object in order to allow configuration
  # of various properties including keywords
  #
  class Configuration < BlankObject
    # Reserved methods are not assignable. They define behaviour needed for
    # the configuration object to work properly.
    #
    RESERVED_METHODS = [
      :initialize,
      :inspect,
      :method_missing,
      :object_id,
      :singleton_class, # needed by rbx
      :to_h,
      :to_s # needed by rbx / 1.9.3 for inspect
    ]

    class << self
      # Make new a private method, but allow __new__ alias. Instantiating
      # configurations is not part of the public API.
      #
      alias_method :__new__, :new
      private :new
    end

    # Initialize a new configuration
    # @param [Hash] options The options to initialize a configuration with
    # @option options [Hash] methods a hash of method names pointing to procs
    # @option options [Proc] not_configured a proc to evaluate for
    #   not_configured properties

    def initialize(options = {}, &block)
      @__methods__ = options.fetch(:methods) { ::Hash.new }
      @__not_configured__ = options.fetch(:not_configured) { ::Hash.new }

      @data = __configuration_hash__

      __instance_eval__(&options[:defaults]) if options[:defaults]
      __instance_eval__(&block) if block

      __install_configuration_methods__
    end

    # Method missing gives access to Kernel methods
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

    # A convenience accessor to get a hash representation of the
    # current state of the configuration
    # @return [Hash] the configuration in hash form
    #
    def to_h
      @data.reduce({}) do |h, (k, v)|
        h[k] = v.is_a?(__class__) ? v.to_h : v

        h
      end
    end

    # A convenience accessor to instantiate a configuration from a hash
    # @param [Hash] h the hash to read into the configuration
    # @return [Configuration] the configuration with values assigned
    # @raise [ConfigurationError] if the given hash ambiguous values
    #     - string and symbol keys with the same string value pointing to
    #     different values
    #
    def from_h(h)
      __test_ambiguity!(h)
      h.each do |property, value|
        p = property.to_sym
        if value.is_a?(::Hash) && __nested?(p)
          @data[p].from_h(value)
        elsif __configurable?(p)
          __assign!(p, value)
        end
      end

      self
    end

    # Inspect a configuration. Implements inspect without exposing internally
    # used instance variables.
    # @param [TrueClass, FalseClass] debug whether to show internals, defaults
    #     to false
    # @return [String] The inspect output for this instance
    #
    def inspect(debug = false)
      unless debug
        '#<%s:0x00%x @data=%s>' % [__class__, object_id << 1, @data.inspect]
      else
        super()
      end
    end

    # @param [Symbol] property The property to test for configurability
    # @return [Boolean] whether the given property is configurable
    #
    def __configurable?(_property)
      fail NotImplementedError, 'must be implemented in subclass'
    end

    # @param [Symbol] property The property to test for
    # @return [Boolean] whether the given property has been configured
    #
    def __configured?(property)
      @data.key?(property)
    end

    # @return [Boolean] whether this configuration is empty
    def __empty?
      @data.empty?
    end

    protected

    # Installs the given configuration methods for this configuration
    # as singleton methods
    #
    def __install_configuration_methods__
      @__methods__.each do |meth, block|
        __test_reserved!(meth)
        __define_singleton_method__(meth, &block) if block.is_a?(::Proc)
      end
    end

    # Instantiates an options hash for a nested property
    # @param [Symbol] property the nested property to instantiate the hash for
    # @return [Hash] a hash to be used for configuration initialization
    #
    def __options_hash_for__(property)
      hash = {}
      hash[:not_configured] =
        __not_configured_hash_for__(property) if @__not_configured__[property]
      hash[:methods] = @__methods__[property] if @__methods__.key?(property)

      hash
    end

    # @param [Symbol] property the property to return the callback for
    # @return [Proc] a block to use when property is called before
    #   configuration, defaults to a block yielding nil
    #
    def __not_configured_callback_for__(property)
      not_configured = @__not_configured__[property] || ::Proc.new { nil }

      unless not_configured.is_a?(::Proc)
        blocks = __collect_blocks__(not_configured)
        not_configured = ->(p) { blocks.each { |b| b.call(p) } }
      end

      not_configured
    end

    # @param [Symbol] property the property to return the not
    #   configured hash option for
    # @return [Hash] a hash which can be used as a not configured
    #   hash in options
    #
    def __not_configured_hash_for__(property)
      hash = ::Hash.new(&@__not_configured__.default_proc)
      hash.merge!(
        @__not_configured__[property]
      ) if @__not_configured__[property].is_a?(::Hash)

      hash
    end

    # @return [Hash] A configuration hash instantiating subhashes
    #   if the key is configurable
    #
    def __configuration_hash__
      ::Hash.new do |h, k|
        h[k] = __class__.__new__(__options_hash_for__(k)) if __configurable?(k)
      end
    end

    # Assigns a value after running the assertions
    # @param [Symbol] property the property to type test
    # @param [Any] value the given value
    #
    def __assign!(property, value)
      __test_reserved!(property)
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
    # @return [Boolean] whether the configuration can delegate
    #   the given method to Kernel
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

    # @param [Symbol] method the method to test for reservedness
    # @raise [Configurations::ReservedMethodError] raises this error if
    #    a property is a reserved method.
    #
    def __test_reserved!(method)
      ::Kernel.fail(
        ::Configurations::ReservedMethodError,
        "#{method} is a reserved method and can not be assigned"
      ) if __is_reserved?(method)
    end

    # @param [Hash] the hash to test for ambiguity
    # @raise [Configurations::ConfigurationError] raises this error if
    #    a property is defined ambiguously
    #
    def __test_ambiguity!(h)
      symbols, others = h.keys.partition { |k| k.is_a?(::Symbol) }
      ambiguous = symbols.map(&:to_s) & others

      unless ambiguous.empty?
        ::Kernel.fail(
          ::Configurations::ConfigurationError,
          "Can not resolve configuration values for #{ambiguous.join(', ')} " \
          "defined as both Symbol and #{others.first.class.name} keys. " \
          'Please resolve the ambiguity.'
        )
      end
    end

    # @param [Symbol] method the method to test for
    # @return [TrueClass, FalseClass] whether the method is reserved
    #
    def __is_reserved?(method)
      RESERVED_METHODS.include?(method)
    end

    # @param [Hash] a hash to collect blocks from
    # @return [Proc] a proc to call all the procs
    #
    def __collect_blocks__(hash)
      hash.reduce([]) do |array, (k, v)|
        array << if v.is_a?(::Hash)
                   __collect_blocks__(v)
                 else
                   v || k
                 end

        array
      end.flatten
    end
  end
end
