module Tests
  module Shared
    module Instantiation
      def self.included(base)
        base.class_eval <<-RUBY
          def test_instantiation_via_new_is_prevented
            configuration_class = #{base.name}.const_get(:TestModule).const_get(:Configuration)
            assert_raises NoMethodError do
              configuration_class.new({})
            end
          end
        RUBY
      end
    end
  end
end
