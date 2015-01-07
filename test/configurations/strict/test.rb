require 'test_helper'

class TestStrict < ConfigurationsTest
  setup_with :strict
  shares_tests :properties, :properties_outside_block, :kernel_methods

  def test_respond_to_writer
    assert_respond_to @configuration, :p1=
  end

  def test_undefined_property
    assert_raises NoMethodError do
      @configuration.p15
    end
  end

  def test_respond_to_undefined_property
    refute_respond_to @configuration, :p15
  end
end
