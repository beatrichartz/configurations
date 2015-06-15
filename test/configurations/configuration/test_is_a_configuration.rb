class TestIsAConfiguration < ConfigurationsTest
  def test_is_a_configuration
    configuration_class = @module.const_get(:Configuration)
    assert @configuration.is_a?(configuration_class), 'Expected configuration to be defined in host module'
  end
end
