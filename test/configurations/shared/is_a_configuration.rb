module Tests
  module Shared
    module IsAConfiguration
      def self.included(base)
        base.class_eval <<-RUBY
          def test_is_a_configuration
            configuration_class = #{base.name}.const_get(:TestModule).const_get(:Configuration)
            assert @configuration.is_a?(configuration_class), "Expected configuration to be defined in host module"
          end
        RUBY
      end
    end
  end
end
