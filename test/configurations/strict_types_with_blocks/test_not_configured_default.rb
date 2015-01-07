require 'test_helper'

class TestStrictTypesWithBlocksNotConfiguredDefault < ConfigurationsTest
  shares_tests :not_configured_default_callback
  setup_with :strict_types_with_blocks
end
