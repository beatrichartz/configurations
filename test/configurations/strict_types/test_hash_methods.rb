require 'test_helper'

class TestHashMethodsOnStrictTypes < ConfigurationsTest
  setup_with :strict_types
  shares_tests :hash_methods

  def test_from_h_outside_block
    old_to_h = @configuration.to_h.dup
    assert_equal(old_to_h, @configuration.from_h(old_to_h).to_h)
  end
end
