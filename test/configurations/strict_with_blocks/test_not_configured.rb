require 'test_helper'

class TestStrictWithBlocksNotConfigured < ConfigurationsTest
  shares_tests :not_configured_callbacks
  setup_with :strict_with_blocks
end
