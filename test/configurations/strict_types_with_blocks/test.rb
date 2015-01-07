require 'test_helper'

class TestStrictTypesWithBlocks < ConfigurationsTest
  shares_tests :properties, :properties_outside_block, :kernel_methods
  setup_with :strict_types_with_blocks

  def test_blocks
    @configuration.p2 = -2
    assert_equal 2, @configuration.p2
  end

  def test_blocks_come_after_typecheck
    assert_raises Configurations::ConfigurationError do
      @configuration.p3.p5.p6 = nil
    end
  end

  def test_set_nested_property_outside_block
    @configuration.p3.p5.p6 = %w(OUTSIDE BLOCK P3 P5 P6)
    assert_equal %w(P6 P5 P3 BLOCK OUTSIDE), @configuration.p3.p5.p6
  end
end
