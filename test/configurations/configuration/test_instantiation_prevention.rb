class TestInstantiationPrevention < ConfigurationsTest
  def test_instantiation_via_new_is_prevented
    configuration_class = @module.const_get(:Configuration)
    assert_raises NoMethodError do
      configuration_class.new({})
    end
  end
end
