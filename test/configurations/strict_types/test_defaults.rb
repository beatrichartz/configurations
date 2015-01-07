require 'test_helper'

class TestStrictTypesWithDefaults < ConfigurationsTest
  setup_with :strict_types
  shares_tests :defaults
end
