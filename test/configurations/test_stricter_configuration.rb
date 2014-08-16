require 'test_helper'

class TestStricterConfiguration < Minitest::Test

  StrictConfigurationTestModule = testmodule_for(Configurations)
  StrictConfigurationTestModule.module_eval do
    configurable :property1, :property2
    configurable String, :property3
    configurable Symbol, property4: :property5, property6: [:property7, :property8]
    configurable Array, property9: { property10: :property11 }
  end

  def setup
    StrictConfigurationTestModule.configure do |c|
      c.property1 = 'BASIC1'
      c.property2 = 'BASIC2'
      c.property3 = 'STRING'
      c.property4.property5 = :something
      c.property6.property7 = :anything
      c.property6.property8 = :everything
      c.property9.property10.property11 = %w(here I am)
    end

    @configuration = StrictConfigurationTestModule.configuration
  end

  def test_configurable_when_set_configurable
    assert_equal 'BASIC1', @configuration.property1
    assert_equal 'BASIC2', @configuration.property2
  end

  def test_configurable_when_set_nested_configurable
    assert_equal :something, @configuration.property4.property5
  end

  def test_configurable_with_same_key_when_set_nested_configurable
    assert_equal :anything, @configuration.property6.property7
    assert_equal :everything, @configuration.property6.property8
  end

  def test_configurable_with_deeply_nested_property
    assert_equal %w(here I am), @configuration.property9.property10.property11
  end

  def test_not_configurable_with_wrong_type
    assert_raises Configurations::ConfigurationError do
      StrictConfigurationTestModule.configure do |c|
        c.property3 = {}
      end
    end
  end

  def test_not_configurable_with_undefined_property
    assert_raises NoMethodError do
      StrictConfigurationTestModule.configure do |c|
        c.property4 = {}
      end
    end
  end

  def test_not_callable_with_undefined_property
    assert_raises NoMethodError do
      @configuration.property12
    end
  end

  def test_not_configurable_with_undefined_nested_property
    assert_raises NoMethodError do
      StrictConfigurationTestModule.configure do |c|
        c.property6.property9 = {}
      end
    end
  end

  def test_not_callable_with_undefined_nested_property
    assert_raises NoMethodError do
      @configuration.property6.property9
    end
  end

end
