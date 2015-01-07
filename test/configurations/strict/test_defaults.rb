require 'test_helper'

class TestStrictWithDefaults < ConfigurationsTest
  setup_with :strict
  shares_tests :defaults
end
