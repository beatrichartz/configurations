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

    configurable :property1, :property2
    configuration_method :property3 do |c|
      MyClass.new(c.property1, c.property2)
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
    assert_equal @configuration.property3.props, [:one, :two]
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
