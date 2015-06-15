class TestInspect < ConfigurationsTest
  setup_with {}

  def inspect_output(_configuration)
    "#<#{self.class.name}::TestModule::Configuration:0x00%x @data={}>" % [@configuration.object_id << 1]
  end

  def test_non_debug_inspect
    expected = inspect_output(@configuration)

    assert @configuration.inspect == expected, "Expected inspect to produce output #{expected.inspect}, but got #{@configuration.inspect.inspect}"
  end

  def test_debug_inspect
    non_debug = inspect_output(@configuration)

    refute @configuration.inspect(true) == non_debug, "Expected debug inspect to delegate to kernel and produce more output, but got #{@configuration.inspect(true).inspect}"
  end
end
