require 'test_helper'

class TestConfigurationRetrievable < Minitest::Test

  RetrievableConfigurationClassModule = testmodule_for(Configurations)
  RetrievableConfigurationClassModule.module_eval do
    class MyClass
      attr_reader :props
      def initialize(*props)
        @props = props
      end
    end

    configurable :property1, :property2
    retrievable :property3 do |c|
      MyClass.new(c.property1, c.property2)
    end
  end

  def setup
    RetrievableConfigurationClassModule.configure do |c|
      c.property1 = :one
      c.property2 = :two
    end

    @configuration = RetrievableConfigurationClassModule.configuration
  end

  def test_configuration_retrievable
    assert_equal @configuration.property3.props, [:one, :two]
  end

  def test_retrievable_overwrite
    assert_raises ArgumentError do
      RetrievableConfigurationClassModule.module_eval do
        retrievable :property2 do |c|
          MyClass.new(c.property2)
        end
      end
    end
  end

end
