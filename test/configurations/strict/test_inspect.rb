require 'test_helper'

class TestStrictInspect < ConfigurationsTest
  setup_with :strict_types_with_blocks do
  end

  shares_tests :inspect
end
