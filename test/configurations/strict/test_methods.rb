require 'test_helper'

class TestMethodsOnStrict < ConfigurationsTest
  setup_with :strict
  shares_tests :methods
end
