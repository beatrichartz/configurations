require 'test_helper'

class TestStrictNotConfiguredDefault < ConfigurationsTest
  shares_tests :not_configured_default_callback
  setup_with :strict
end
