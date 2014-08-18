require 'test_helper'

class TestConfigurationMethods < Minitest::Test

  ConfigurationMethodsClassModule = testmodule_for(Configurations)
  ConfigurationMethodsClassModule.module_eval do
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

  def setup
    ConfigurationMethodsClassModule.configure do |c|
      c.property1 = :one
      c.property2 = :two
    end

    @configuration = ConfigurationMethodsClassModule.configuration
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

  def test_method_missing_on_kernel_method
    assert_raises StandardError do
      @configuration.raise StandardError
    end
  end

  def test_respond_to_missing_on_kernel_method
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

  def test_configuration_method_overwrite
    assert_raises ArgumentError do
      ConfigurationMethodsClassModule.module_eval do
        configuration_method :property2 do |c|
          MyClass.new(c.property2)
        end
      end
    end
  end

end
