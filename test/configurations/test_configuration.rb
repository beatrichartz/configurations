require 'test_helper'

class TestConfiguration < Minitest::Test

  ConfigurationTestModule = testmodule_for(Configurations)
  ConfigurationTestModule.module_eval do
    configuration_defaults do |c|
      c.uh.this.is.neat = 'NEAT'
      c.pah = 'PUH'
      c.overwrite.this = ''
      c.overwriteee = 'BLA'
    end
  end
  def setup
    ConfigurationTestModule.configure do |c|
      c.basic = 'BASIC'
      c.class = 'KEY'
      c.overwriteee = 'YEAH'
      c.overwrite.this = 'OVERWRITE'
      c.github.repo = 'github.com/beatrichartz/configurations'
      c.github.access_key = 'ABCDEF'
      c.something.else.entirely.nested.deep.below = 'something'
    end

    @configuration = ConfigurationTestModule.configuration
  end

  def test_configuration_is_subclass_of_host_module
    assert_equal true, ConfigurationTestModule.const_defined?(:Configuration)
  end

  def test_configuration_to_h
    assert_equal(
      {
        uh:
          {
            this: { is: { neat: 'NEAT' } }
          },
        pah: 'PUH',
        overwrite: {
          this: 'OVERWRITE'
        },
        overwriteee: 'YEAH',
        basic: 'BASIC',
        class: 'KEY',
        github: {
          repo: 'github.com/beatrichartz/configurations',
          access_key: 'ABCDEF'
        },
        something: { else: { entirely: { nested: { deep: { below: 'something' } } } } }
      }, @configuration.to_h)
  end

  def test_defaults
    assert_equal 'PUH', @configuration.pah
  end

  def test_defaults_overwrite
    assert_equal 'YEAH', @configuration.overwriteee
  end

  def test_nested_defaults
    assert_equal 'NEAT', @configuration.uh.this.is.neat
  end

  def test_nested_defaults_overwrite
    assert_equal 'OVERWRITE', @configuration.overwrite.this
  end

  def test_configurable
    assert_equal 'BASIC', @configuration.basic
  end

  def test_keywords_configurable
    assert_equal 'KEY', @configuration.class
  end

  def test_nested_properties_with_same_key_configurable
    assert_equal 'github.com/beatrichartz/configurations', @configuration.github.repo
    assert_equal 'ABCDEF', @configuration.github.access_key
  end

  def test_deeply_nested_properties_configurable
    assert_equal 'something', @configuration.something.else.entirely.nested.deep.below
  end

  def test_not_callable_with_undefined_property
    assert_raises NoMethodError do
      @configuration.somethings
    end
  end

end
