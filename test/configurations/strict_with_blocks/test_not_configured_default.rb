require 'test_helper'

class TestStrictWithBlocksNotConfiguredDefault < ConfigurationsTest
  shares_tests :not_configured_default_callback
  setup_with :strict_with_blocks
end
