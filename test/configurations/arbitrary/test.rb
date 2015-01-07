require 'test_helper'

class TestArbitrary < ConfigurationsTest
  shares_tests :properties, :kernel_methods

  def test_respond_to_on_writer_while_writeable
    TestModule.configure do |c|
      assert_respond_to :p1=, c
    end
  end

  def test_respond_to_on_writer_when_not_writeable
    refute_respond_to @configuration, :p1=
  end

  def test_undefined_property
    assert_nil @configuration.p15
  end

  def test_respond_to_undefined_property
    assert_respond_to @configuration, :p15
  end
end
