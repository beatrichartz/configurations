require 'test_helper'

class TestStrictTypesNotConfigured < ConfigurationsTest
  setup_with :strict_types
  shares_tests :not_configured_callbacks
end
