require 'thread'

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
      base.instance_eval do
        extend ClassMethods

        # call configuration_mutex once to initialize the value
        #
        initialize_configuration!
      end
    end

    def underscore_camelized(string)
      string.gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
    end

    # Installs #configure in base, and makes sure that it will instantiate
    # configuration as a subclass of the host module
    #
    def install_configure_in(base)
      base.instance_eval <<-EOF
        # Configuration class for host module
        #
        #{base.name}::Configuration = Class.new(Configurations::Configuration)

        # The central configure method
        # @params [Proc] block the block to configure host module with
        # @raise [ArgumentError] error when not given a block
        # @example Configure a configuration
        #   MyGem.configure do |c|
        #     c.foo = :bar
        #   end
        #
        def self.configure(&block)
          semaphore.synchronize do
            fail ArgumentError, "configure needs a block" unless block_given?
            include_configuration_type!(#{base.name}::Configuration)

            set_configuration!(&block)
          end
        end

        # A reader for Configuration
        #
        def configuration
          semaphore.synchronize do
            return @configuration if @configuration

            if @configuration_defaults
              include_configuration_type!(#{base.name}::Configuration)
              set_configuration! { }
            end
          end
        end


        private

        # Sets the configuration instance variable
        #
        def self.set_configuration!(&block)
          @configuration = #{base.name}::Configuration.__new__(
                                                      configuration_options,
                                                      &block
                                                    )
        end

        @semaphore = Mutex.new
        def self.semaphore
          @semaphore
        end

      EOF
    end

    # Class methods that will get installed in the host module
    #
    module ClassMethods
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
        @configurable_properties ||= Maps::Properties.new
        @configurable_types ||= Maps::Types.new
        @configurable_blocks ||= Maps::Blocks.new

        type, properties = extract_type(properties)
        @configurable_properties.add(properties)
        @configurable_types.add(type, properties)
        @configurable_blocks.add(block, properties)
      end

      def extract_type(properties)
        if properties.first.is_a?(Module)
          [properties.first, properties[1...properties.size]]
        else
          [nil, properties]
        end
      end

      # returns whether a property is set to be configurable
      # @param [Symbol] property the property to ask status for
      # @return [Boolean] whether the property is configurable
      #
      def configurable?(property)
        defined?(@configurable_properties) &&
          @configurable_properties &&
          @configurable_properties.configurable?(Path.new([property]))
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
        fail(
          ArgumentError,
          "can't be configuration property and a method"
        ) if configurable?(method)

        @configuration_method_blocks ||= Maps::Blocks.new
        @configuration_method_blocks.add(block, [method])
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
        @not_configured_blocks ||= Maps::Blocks.new
        @not_configured_blocks.add(block, properties)

        if properties.empty?
          @not_configured_blocks.add_default(block)
        end
      end

      private

      def initialize_configuration!
        @configuration = nil
      end

      # Include the configuration type module into the host configuration class
      #
      def include_configuration_type!(base)
        return if base.ancestors.include?(configuration_type)

        base.send :include, configuration_type
      end

      # @return the class name of the configuration class to use
      #
      def configuration_type
        if defined?(@configurable_properties) && @configurable_properties && !@configurable_properties.empty?
          Configurations::Strict
        else
          Configurations::Arbitrary
        end
      end

      # @return a hash of configuration options with no nil values
      #
      def configuration_options
        {
          defaults:
            defined?(@configuration_defaults) && @configuration_defaults,
          properties:
            defined?(@configurable_properties) && @configurable_properties,
          types:
            defined?(@configurable_types) && @configurable_types,
          blocks:
            defined?(@configurable_blocks) && @configurable_blocks,
          method_blocks:
            defined?(@configuration_method_blocks) && @configuration_method_blocks,
          not_configured_blocks:
            defined?(@not_configured_blocks) && @not_configured_blocks,
        }.keep_if { |_, value| value }
      end
    end
  end
end
