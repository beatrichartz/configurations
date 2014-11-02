require 'test_helper'

class TestStricterConfiguration < Minitest::Test
  module StrictConfigurationTestModule
    include Configurations

    configurable :property1, :property2
    configurable String, :property3
    configurable Symbol, property4: :property5, property6: [:property7, :property8]
    configurable Fixnum, property6: :property14
    configurable Fixnum, property4: :property12
    configurable Array, property9: { property10: { property11: :property12 } }
    configurable Hash, property9: { property10: { property11: :property13 } }
  end

  module StrictConfigurationTestModuleDefaultsError
    include Configurations

    configurable :property1, :property2

    not_configured do |prop|
      raise StandardError, 'Problem here'
    end
  end

  def setup
    StrictConfigurationTestModule.configure do |c|
      c.property1 = 'BASIC1'
      c.property2 = 'BASIC2'
      c.property3 = 'STRING'
      c.property4.property5 = :something
      c.property4.property12 = 12
      c.property6.property7 = :anything
      c.property6.property8 = :everything
      c.property6.property14 = 555
      c.property9.property10.property11.property12 = %w(here I am)
      c.property9.property10.property11.property13 = { hi: :bye }
    end
    StrictConfigurationTestModuleDefaultsError.configure do |c|
      c.property1 = 'BASIC3'
    end

    @configuration = StrictConfigurationTestModule.configuration
    @configuration_defaults_error = StrictConfigurationTestModuleDefaultsError.configuration
  end

  def test_configurable_when_set_configurable
    assert_equal 'BASIC1', @configuration.property1
    assert_equal 'BASIC2', @configuration.property2
  end

  def test_configurable_when_set_nested_configurable
    assert_equal :something, @configuration.property4.property5
  end

  def test_configurable_with_nested_calls_and_deeply_nested_property
    assert_equal 12, @configuration.property4.property12
  end

  def test_configurable_with_nested_calls_and_added_property
    assert_equal 555, @configuration.property6.property14
  end

  def test_configurable_type_assertion_with_nested_calls_and_added_property
    assert_raises Configurations::ConfigurationError do
      StrictConfigurationTestModule.configure do |c|
        c.property6.property14 = ''
      end
    end
  end

  def test_strict_configuration_to_h
    assert_equal({
                   property4: {
                     property5: :something,
                     property12: 12
                   },
                   property6: {
                     property7: :anything,
                     property8: :everything,
                     property14: 555
                   },
                   property9: {
                     property10: {
                       property11: {
                         property12: %w(here I am),
                         property13: {
                           hi: :bye
                         }
                       }
                     }
                   },
                   property1: 'BASIC1',
                   property2: 'BASIC2',
                   property3: 'STRING'
                 }, @configuration.to_h)
  end

  def test_strict_configuration_from_h
    old_to_h = @configuration.to_h.dup
    assert_equal(old_to_h, StrictConfigurationTestModule.configure{ |c| c.from_h(old_to_h) }.to_h)
  end

  def test_configurable_with_same_key_when_set_nested_configurable
    assert_equal :anything, @configuration.property6.property7
    assert_equal :everything, @configuration.property6.property8
  end

  def test_configurable_with_deeply_nested_property
    assert_equal %w(here I am), @configuration.property9.property10.property11.property12
  end

  def test_configurable_with_nested_calls_and_deeply_nested_property
    assert_equal({ hi: :bye }, @configuration.property9.property10.property11.property13)
  end

  def test_configurable_type_restricted_with_nested_calls_and_deeply_nested_property
    assert_raises Configurations::ConfigurationError do
      StrictConfigurationTestModule.configure do |c|
        c.property9.property10.property11.property13 = ''
      end
    end
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

  def test_respond_to_with_undefined_property
    assert_equal false, @configuration.respond_to?(:property12)
  end

  def test_not_callable_with_undefined_property
    assert_raises NoMethodError do
      @configuration.property12
    end
  end

  def test_not_configured_callback
    assert_raises StandardError do
      @configuration_defaults_error.property2
    end
  end

  def test_not_configured_callback_not_triggered_for_configured
    assert_equal 'BASIC3', @configuration_defaults_error.property1
  end

  def test_not_configurable_with_undefined_nested_property
    assert_raises NoMethodError do
      StrictConfigurationTestModule.configure do |c|
        c.property6.property9 = {}
      end
    end
  end

  def test_callable_with_undefined_nested_property
    assert_nil @configuration.property6.property9
  end

end
