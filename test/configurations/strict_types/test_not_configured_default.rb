require 'test_helper'

class TestStrictTypesNotConfiguredDefault < ConfigurationsTest
  shares_tests :not_configured_default_callback
  setup_with :strict_types
end
