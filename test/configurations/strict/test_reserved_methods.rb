require 'test_helper'

class TestStrictReservedMethods < ConfigurationsTest
  def test_reserved_methods_not_configurable
    assert_raises Configurations::ReservedMethodError do
      @module.class_eval do
        configurable :inspect
      end

      setup
    end
  end
end
