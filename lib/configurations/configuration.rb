module Configurations
  # Configuration is a blank object in order to allow configuration
  # of various properties including keywords
  #
  class Configuration < BlankObject

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
      @data = Data.new(__configuration_hash__)
      @path = options.fetch(:path) { Path.new }
      @data_map = options.fetch(:data) { Maps::Data.new }

      @methods = options.fetch(:methods) { ::Hash.new }
      @method_blocks = options.fetch(:method_blocks) { Maps::Blocks.new }
      @not_configured_blocks = options.fetch(:not_configured_blocks) { Maps::Blocks.new }

      @reserved_method_validator = Validators::ReservedMethods.new
      @key_ambiguity_validator = Validators::Ambiguity.new

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
      @key_ambiguity_validator.validate!(h)

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
    def __configurable?(property)
      if defined?(@configurable_properties) && @configurable_properties
        @configurable_properties.configurable?(@path.add(property))
      else
        true
      end
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
      entries = @method_blocks.entries_at(@path)
      entries.each do |meth, entry|
        @reserved_method_validator.validate!(meth)
        __define_singleton_method__(meth, &entry.block)
      end
    end

    # Instantiates an options hash for a nested property
    # @param [Symbol] property the nested property to instantiate the hash for
    # @return [Hash] a hash to be used for configuration initialization
    #
    def __options_hash_for__(property)
      nested_path = @path.add(property)

      hash = {}
      hash[:path] = nested_path
      hash[:data] = @data_map
      hash[:properties] = defined?(@properties) && @properties

      hash[:not_configured_blocks] = @not_configured_blocks

      hash[:method_blocks] = @method_blocks
      hash[:methods] = @methods[property] if @methods.key?(property)

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
      @data_map.add_entry(@path.add(property), value)
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

  end
end
