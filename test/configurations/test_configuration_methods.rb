require 'test_helper'

class TestConfigurationMethods < Minitest::Test

  module ConfigurationMethodsClassModule
    include Configurations

    class MyClass
      attr_reader :props
      def initialize(*props)
        @props = props
      end
    end

    context = 'CONTEXT'
    configurable :property1, :property2
    configuration_method :method1 do
      MyClass.new(property1, property2)
    end
    configuration_method :method2 do
      context + property1.to_s
    end
    configuration_method :method3 do |arg|
      arg + property1.to_s
    end
    configuration_method :kernel_raise do
      raise StandardError, 'hell'
    end
  end

  module ConfigurationNoMethodsClassModule
    include Configurations

    configurable :property3
  end

  def setup
    ConfigurationMethodsClassModule.configure do |c|
      c.property1 = :one
      c.property2 = :two
    end

    ConfigurationNoMethodsClassModule.configure do |c|
      c.property3 = :three
    end

    @configuration = ConfigurationMethodsClassModule.configuration
    @no_method_configuration = ConfigurationNoMethodsClassModule.configuration
  end

  def test_configuration_method
    assert_equal [:one, :two], @configuration.method1.props
  end

  def test_configuration_method_with_context
    assert_equal 'CONTEXTone', @configuration.method2
  end

  def test_configuration_method_with_arguments
    assert_equal 'ARGone', @configuration.method3('ARG')
  end

  def test_kernel_methods_in_configuration_method
    assert_raises StandardError, 'hell' do
      @configuration.kernel_raise
    end
  end

  def test_configuration_method_overwrite
    assert_raises ArgumentError do
      ConfigurationMethodsClassModule.module_eval do
        configuration_method :property2 do |c|
          MyClass.new(c.property2)
        end
      end
    end
  end

  def test_configuration_methods_unaffected
    assert_raises NoMethodError do
      @no_method_configuration.method3('ARG')
    end
  end

end
