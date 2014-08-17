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
      #
      def configurable(*properties)
        type = properties.shift if properties.first.is_a?(Class)
        @configurable ||= {}
        @configurable.merge!(to_configurable_hash(properties, type))
      end

      private

      # Instantiates a configurable hash from a property and a type
      # @param [Symbol, Hash, Array] properties configurable properties, either single or nested
      # @param [Class] type the type to assert, if any
      # @return a hash with configurable values pointing to their types
      #
      def to_configurable_hash(properties, type)
        Hash[properties.zip(Array(type) * properties.size)]
      end
    end
  end
end
