module Configurations
  # Module configurable provides the API of configurations
  #
  module Configurable
    extend self

    # Once included, Configurations installs three methods in the host module: configure, configuration_defaults and configurable
    #
    def included(base)
      install_configure_in(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    # Installs #configure in base, and makes sure that it will instantiate configuration as a subclass of the host module
    #
    def install_configure_in(base)
      base.class_eval <<-EOF
        class << self
          # The central configure method
          # @params [Proc] block the block to configure host module with
          # @raise [ArgumentError] error when not given a block
          #
          def configure(&block)
            raise ArgumentError, 'can not configure without a block' unless block_given?
            @configuration = #{self}::Configuration.new(@configuration_defaults, @configurable, &block)
          end
        end
      EOF
    end

    # Class methods that will get installed in the host module
    #
    module ClassMethods
      # A reader for Configuration
      #
      def configuration
        @configuration ||= @configuration_defaults && configure { }
      end

      # Configuration defaults can be used to set the defaults of any Configuration
      # @param [Proc] block setting the default values of the configuration
      #
      def configuration_defaults(&block)
        @configuration_defaults = block
      end

      # configurable can be used to set the properties which should be configurable, as well as a type which
      # the given property should be asserted to
      # @param [Class, Symbol, Hash] properties a type as a first argument to type assert (if any) or nested properties to allow for setting
      # @param [Proc] block a block with arity 2 to evaluate when a property is set. It will be given: property name and value
      #
      def configurable(*properties, &block)
        type = properties.shift if properties.first.is_a?(Class)
        @configurable ||= {}
        @configurable.merge!(to_configurable_hash(properties, type, &block))
      end

      # returns whether a property is set to be configurable
      # @param [Symbol] property the property to ask status for
      #
      def configurable?(property)
        @configurable.is_a?(Hash) && @configurable.has_key?(property)
      end

      # configuration method can be used to retrieve properties from the configuration which use your gem's context
      # @param [Class, Symbol, Hash] properties properties for retrieval
      # @param [Proc] block the block to evaluate
      #
      def configuration_method(method, &block)
        raise ArgumentError, "#{method} can not be both a configurable property and a configuration method" if configurable?(method)

        Configuration.class_eval do
          define_method method do
            block.call(self)
          end
        end
      end

      private

      # Instantiates a configurable hash from a property and a type
      # @param [Symbol, Hash, Array] properties configurable properties, either single or nested
      # @param [Class] type the type to assert, if any
      # @return a hash with configurable values pointing to their types
      #
      def to_configurable_hash(properties, type, &block)
        assertion_hash = {}
        assertion_hash.merge! block: block if block_given?
        assertion_hash.merge! type: type if type

        assertions = ([assertion_hash] * properties.size)
        Hash[properties.zip(assertions)]
      end
    end
  end
end
