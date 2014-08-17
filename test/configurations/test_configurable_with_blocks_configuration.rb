require 'test_helper'

class TestStricterConfigurationWithBlock < Minitest::Test

  BlocksConfigurationTestModule = testmodule_for(Configurations)
  BlocksConfigurationTestModule.module_eval do
    configurable :property1, :property2 do |value|
      value.to_s + 'oooh'
    end
    configurable String, :property3, property4: [:property5, :property6] do |value|
      raise ArgumentError, 'TEST2' unless %w(hello bye).include?(value)
      value
    end
  end

  def setup
    BlocksConfigurationTestModule.configure do |c|
      c.property1 = :one
      c.property2 = :two
      c.property3 = 'hello'
      c.property4.property5 = 'hello'
      c.property4.property6 = 'bye'
    end

    @configuration = BlocksConfigurationTestModule.configuration
  end

  def test_configurable_when_set_configurable_with_block
    assert_equal 'oneoooh', @configuration.property1
    assert_equal 'twooooh', @configuration.property2
  end

  def test_nested_configurable_when_set_configurable_with_block
    assert_equal 'hello', @configuration.property4.property5
    assert_equal 'bye', @configuration.property4.property6
  end

  def test_evaluates_block_for_nested_properties_when_set_configurable_with_block
    assert_raises ArgumentError, 'TEST2' do
      BlocksConfigurationTestModule.configure do |c|
        c.property4.property5 = 'oh'
      end
    end
  end

end
