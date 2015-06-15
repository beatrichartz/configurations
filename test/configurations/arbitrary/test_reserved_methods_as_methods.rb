require 'test_helper'

class TestArbitraryReservedMethodsAsMethods < ConfigurationsTest
  def test_reserved_methods_not_allowed_as_methods
    assert_raises Configurations::ReservedMethodError do
      @module.class_eval do
        configuration_method :to_h do
          'h'
        end
      end

      setup
    end
  end
end
