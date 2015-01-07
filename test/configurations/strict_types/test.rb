require 'test_helper'

class TestStrictTypes < ConfigurationsTest
  setup_with :strict_types
  shares_tests :properties, :properties_outside_block, :kernel_methods

  def test_configure_with_wrong_type
    assert_raises Configurations::ConfigurationError do
      @configuration.p1 = :symbol
    end
  end

  def test_configure_nested_with_wrong_type
    assert_raises Configurations::ConfigurationError do
      @configuration.p3.p5.p6 = 'STRING'
    end
  end
end
