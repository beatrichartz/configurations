require 'test_helper'

class TestStrictTypesWithBlocksNotConfigured < ConfigurationsTest
  shares_tests :not_configured_callbacks
  setup_with :strict_types_with_blocks
end
