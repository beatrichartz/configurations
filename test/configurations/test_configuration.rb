require 'test_helper'

class TestConfiguration < Minitest::Test

  ConfigurationTestModule = testmodule_for(Configurations)
  ConfigurationDefaultTestModule = testmodule_for(Configurations)
  ConfigurationNoDefaultTestModule = testmodule_for(Configurations)

  ConfigurationTestModule.module_eval do
    configuration_defaults do |c|
      c.uh.this.is.neat = 'NEAT'
      c.pah = 'PUH'
      c.overwrite.this = ''
      c.overwriteee = 'BLA'
    end
  end

  ConfigurationDefaultTestModule.module_eval do
    configuration_defaults do |c|
      c.set = 'SET'
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

  def test_defaults_to_nil_when_instructed
    ConfigurationTestModule.configuration_values_default_to_nil!
    assert_nil ConfigurationTestModule.configuration.unset_value
  end

  def test_explicit_values_non_nil_when_defaults_nil
    ConfigurationTestModule.configure { |c| c.basic = 'BASIC' }
    ConfigurationTestModule.configuration_values_default_to_nil!
    assert_nil ConfigurationTestModule.configuration.unset_value
    assert_equal 'BASIC', ConfigurationTestModule.configuration.basic
  end

  def test_configuration_is_subclass_of_host_module
    assert_equal true, ConfigurationTestModule.const_defined?(:Configuration)
  end

  def test_configuration_to_h
    assert_equal({
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

  def test_configuration_from_h
    old_to_h = @configuration.to_h.dup
    assert_equal(old_to_h, ConfigurationTestModule.configure{ |c| c.from_h(old_to_h) }.to_h)
  end

  def test_not_configurable_unless_block_given
    assert_raises ArgumentError do
      ConfigurationTestModule.configure
    end
  end

  def test_defaults
    assert_equal 'PUH', @configuration.pah
  end

  def test_defaults_without_configure
    assert_equal 'SET', ConfigurationDefaultTestModule.configuration.set
  end

  def test_no_defaults_without_configure
    assert_nil ConfigurationNoDefaultTestModule.configuration
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

  def test_method_missing_on_kernel_method
    assert_raises StandardError do
      @configuration.raise StandardError
    end
  end

  def test_respond_to_on_writer_while_writeable
    ConfigurationTestModule.configure do |c|
      assert_equal true, c.respond_to?(:pah=)
    end
  end

  def test_respond_to_on_writer_when_not_writeable
    assert_equal false, @configuration.respond_to?(:pah=)
  end

  def test_respond_to_on_kernel_method
    assert_equal true, @configuration.respond_to?(:puts)
  end

  def test_method_missing_on_non_kernel_method
    assert_raises NoMethodError do
      @configuration.blabla
    end
  end

  def test_respond_to_missing_on_non_kernel_method
    assert_equal false, @configuration.respond_to?(:bbaaaaa)
  end

end
