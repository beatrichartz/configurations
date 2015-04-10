require 'test_helper'

class TestReservedMethods < ConfigurationsTest
  def test_raises_when_setup_with_reserved_methods
    assert_raises Configurations::ReservedMethodError do
      self.class.setup_with do |c|
        c.to_s = 'bla'
      end

      setup
    end
  end
end
