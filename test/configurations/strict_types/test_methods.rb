require 'test_helper'

class TestMethodsOnStrictTypes < ConfigurationsTest
  setup_with :strict_types
  shares_tests :methods
end
