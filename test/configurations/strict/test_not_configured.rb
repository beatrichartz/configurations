require 'test_helper'

class TestStrictNotConfigured < ConfigurationsTest
  setup_with :strict
  shares_tests :not_configured_callbacks
end
