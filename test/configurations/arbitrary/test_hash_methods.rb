require 'test_helper'

class TestHashMethods < ConfigurationsTest
  shares_tests :hash_methods

  def test_from_h_raises_when_not_writeable
    assert_raises ArgumentError do
      @configuration.from_h({})
    end
  end
end
