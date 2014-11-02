require 'test_helper'

class TestConfiguration < Minitest::Test

  module ConfigurationTestModule
    include Configurations
    configuration_defaults do |c|
      c.uh.this.is.neat = 'NEAT'
      c.pah = 'PUH'
      c.overwrite.this = ''
      c.overwriteee = 'BLA'
    end
  end

  module ConfigurationDefaultTestModule
    include Configurations
    configuration_defaults do |c|
      c.set = 'SET'
    end
  end

  module ConfigurationNoDefaultTestModule
    include Configurations
  end

  module ConfigurationNotConfiguredTestModule
    include Configurations
    configuration_defaults do |c|
      c.set.set = 'SET'
    end

    when_not_configured do |property|
      raise ArgumentError, "#{property} must be configured"
    end
  end

  def setup
    ConfigurationTestModule.configure do |c|
      c.basic = 'BASIC'
      c.class = 'KEY'
      c.puts = 'OH'
      c.overwriteee = 'YEAH'
      c.overwrite.this = 'OVERWRITE'
      c.github.repo = 'github.com/beatrichartz/configurations'
      c.github.access_key = 'ABCDEF'
      c.something.else.entirely.nested.deep.below = 'something'
    end

    @configuration = ConfigurationTestModule.configuration
    @not_configured_configuration = ConfigurationNotConfiguredTestModule.configuration
    @defaults_configuration = ConfigurationDefaultTestModule.configuration
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
                   puts: 'OH',
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
    assert_equal 'SET', @defaults_configuration.set
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

  def test_respond_to_with_undefined_property
    assert_equal true, @configuration.respond_to?(:somethings)
  end

  def test_nil_with_undefined_property
    assert_nil @configuration.somethings
  end

  def test_overwritten_kernel_method
    assert_equal 'OH', @configuration.puts
  end

  def test_not_configured_callback
    assert_raises ArgumentError do
      @not_configured_configuration.something
    end
  end

  def test_nested_not_configured_callback
    assert_raises ArgumentError do
      @not_configured_configuration.set.something
    end
  end

  def test_nested_configured_property_with_not_configured
    assert_equal 'SET', @not_configured_configuration.set.set
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
    assert_equal true, @configuration.respond_to?(:raise)
  end

  def test_method_missing_on_non_kernel_method
    assert_nil @configuration.blabla
  end

  def test_respond_to_missing_on_non_kernel_method
    assert_equal true, @configuration.respond_to?(:bbaaaaa)
  end

end
