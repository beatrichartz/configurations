require 'test_helper'

class TestConfigurationSharedNothing < MiniTest::Test
  module TestModule
    include Configurations

    configuration_defaults do |c|
      c.a = 'b'
    end
  end

  def test_shared_nothing_default
    with_gc_disabled do
      ids = 1000.times.map do
        i = 0
        t = Thread.new do
          i = TestModule.configuration.object_id
        end

        t.join

        i
      end.map(&:object_id)

      assert_equal 1000, ids.uniq.size
    end
  end

  def test_shared_nothing_config
    there = TestModule.configuration.a
    t = Thread.new do
      TestModule.configure do |c|
        c.a = 'c'
      end

      there = TestModule.configuration.a
    end

    t.join
    here = TestModule.configuration.a

    refute_equal here, there
  end

  def with_gc_disabled(&block)
    GC.disable
    yield
    GC.enable
  end

end
