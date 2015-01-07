module Configurations
  # Module configurable provides the API of configurations
  #
  module Configurable
    extend self

    # Once included, Configurations installs three methods in the host module:
    # configure, configuration_defaults and configurable
    #
    def included(base)
      install_configure_in(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    # Installs #configure in base, and makes sure that it will instantiate
    # configuration as a subclass of the host module
    #
    def install_configure_in(base)
      base.class_eval <<-EOF
        # The central configure method
        # @params [Proc] block the block to configure host module with
        # @raise [ArgumentError] error when not given a block
        # @example Configure a configuration
        #   MyGem.configure do |c|
        #     c.foo = :bar
        #   end
        #
        def self.configure(&block)
          fail ArgumentError, "configure needs a block" unless block_given?
          @configuration = #{base.name}.const_get(configuration_type).new(
                                                          configuration_options,
                                                          &block
                                                        )
        end
      EOF
    end

    # Class methods that will get installed in the host module
    #
    module ClassMethods
      # A reader for Configuration
      #
      def configuration
        @configuration ||= @configuration_defaults && configure {}
      end

      # Configuration defaults can be used to set the defaults of
      # any Configuration
      # @param [Proc] block setting the default values of the configuration
      #
      def configuration_defaults(&block)
        @configuration_defaults = block
      end

      # configurable can be used to set the properties which should be
      # configurable, as well as a type which the given property should
      # be asserted to
      # @param [Class, Symbol, Hash] properties a type as a first argument to
      #   type assert (if any) or nested properties to allow for setting
      # @param [Proc] block a block with arity 2 to evaluate when a property
      #   is set. It will be given: property name and value
      # @example Define a configurable property
      #   configurable :foo
      # @example Define a type asserted, nested property for type String
      #   configurable String, bar: :baz
      # @example Define a custom assertion for a property
      #   configurable biz: %i(bi bu) do |value|
      #     unless %w(a b c).include?(value)
      #       fail ArgumentError, 'must be one of a, b, c'
      #     end
      #   end
      #
      def configurable(*properties, &block)
        type = properties.shift if properties.first.is_a?(Class)

        @configurable ||= {}
        @configurable.merge! to_configurable_hash(properties, type, &block)
      end

      # returns whether a property is set to be configurable
      # @param [Symbol] property the property to ask status for
      # @return [Boolean] whether the property is configurable
      #
      def configurable?(property)
        @configurable.is_a?(Hash) && @configurable.key?(property)
      end

      # configuration method can be used to retrieve properties
      # from the configuration
      # which use your gem's context
      # @param [Class, Symbol, Hash] method the method to define
      # @param [Proc] block the block to evaluate
      # @example Define a configuration method 'foobararg'
      #   configuration_method :foobararg do |arg|
      #     foo + bar + arg
      #   end
      # @example Define a configuration method on a nested property
      #   configuration_method foo: { bar: :arg } do
      #     baz + biz
      #   end
      #
      def configuration_method(method, &block)
        fail ArgumentError, "can't be configuration property and a method" if configurable?(method)

        @configuration_methods ||= {}
        method_hash = if method.is_a?(Hash)
                        ingest_configuration_block!(method, &block)
                      else
                        { method => block }
                      end

        @configuration_methods.merge! method_hash
      end

      # not_configured defines the behaviour when a property has not been
      # configured. This can be useful for presence validations of certain
      # properties or behaviour for undefined properties deviating from the
      # original behaviour.
      # @param [Array, Symbol, Hash] properties the properties to install
      #   the callback on. If omitted, the callback will be installed on
      #   all properties that have no specific callbacks
      # @param [Proc] block the block to evaluate when a property
      #   has not been configured
      # @yield [Symbol] the property that has not been configured
      # @example Define a specific not_configured callback
      #   not_configured :property1, property2: :property3 do |property|
      #     raise ArgumentError, "#{property} should be configured"
      #   end
      # @example Define a catch-all not_configured callback
      #   not_configured do |property|
      #     raise StandardError, "You did not configure #{property}"
      #   end
      #
      def not_configured(*properties, &block)
        @not_configured ||= {}

        if properties.empty?
          @not_configured.default_proc = ->(h, k) { h[k] = block }
        else
          nested_merge_not_configured_hash(*properties, &block)
        end
      end

      # @return the class name of the configuration class to use
      #
      def configuration_type
        if @configurable.nil? || @configurable.empty?
          :ArbitraryConfiguration
        else
          :StrictConfiguration
        end
      end

      private

      # Instantiates a configurable hash from a property and a type
      # @param [Symbol, Hash, Array] properties configurable properties,
      #   either single or nested
      # @param [Class] type the type to assert, if any
      # @return a hash with configurable values pointing to their types
      #
      def to_configurable_hash(properties, type, &block)
        assertion_hash = {}
        assertion_hash.merge! block: block if block_given?
        assertion_hash.merge! type: type if type

        zip_to_hash(assertion_hash, *properties)
      end

      # Makes all values of hash point to block
      # @param [Hash] hash the hash to modify
      # @param [Proc] block the block to point to
      # @return a hash with all previous values being keys pointing to block
      #
      def ingest_configuration_block!(hash, &block)
        hash.each do |k, v|
          value = if v.is_a?(Hash)
                    ingest_configuration_block!(v, &block)
                  else
                    zip_to_hash(block, *Array(v))
                  end

          hash.merge! k => value
        end
      end

      # @return a hash of configuration options with no nil values
      #
      def configuration_options
        {
          defaults: @configuration_defaults,
          methods: @configuration_methods,
          configurable: @configurable,
          not_configured: @not_configured
        }.delete_if { |_, value| value.nil? }
      end

      # merges the properties given into a not_configured hash
      # @param [Symbol, Hash, Array] properties the properties to merge
      # @param [Proc] block the block to point the properties to when
      #  not configured
      #
      def nested_merge_not_configured_hash(*properties, &block)
        nested = properties.last.is_a?(Hash) ? properties.pop : {}
        nested = ingest_configuration_block!(nested, &block)
        props = zip_to_hash(block, *properties)

        @not_configured.merge! nested, &method(:configuration_deep_merge)
        @not_configured.merge! props, &method(:configuration_deep_merge)
      end

      # Solves merge conflicts when merging
      # @param [Symbol] key the key that conflicts
      # @param [Anything] oldval the value of the left side of the merge
      # @param [Anything] newval the value of the right side of the merge
      # @return a mergable value with conflicts solved
      #
      def configuration_deep_merge(_key, oldval, newval)
        if oldval.is_a?(Hash) && newval.is_a?(Hash)
          oldval.merge(newval, &method(:configuration_deep_merge))
        else
          Array(oldval) + Array(newval)
        end
      end

      # Zip a value with keys to a hash so all keys point to the value
      # @param [Anything] value the value to point to
      # @param [Array] keys the keys to install
      #
      def zip_to_hash(value, *keys)
        Hash[keys.zip([value] * keys.size)]
      end
    end
  end
end
