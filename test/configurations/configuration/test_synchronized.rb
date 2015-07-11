require 'test_helper'

class TestConfigurationSynchronized < MiniTest::Test
  module TestModule
    include Configurations

    configuration_defaults do |c|
      c.a = 'b'
    end
  end

  def test_configuration_synchronized
    with_gc_disabled do
      ids = []
      threads = 100.times.map do |i|
        Thread.new do
          sleep rand(1000) / 1000.0
          ids << TestModule.configure do |c|
            c.a = i
          end.a
        end
      end
      threads.each(&:join)

      assert_equal 100, ids.uniq.size
    end
  end

  def test_one_instance_mutation
    there = TestModule.configuration.a
    t = Thread.new do
      TestModule.configure do |c|
        c.a = 'c'
      end

      there = TestModule.configuration.a
    end

    t.join
    here = TestModule.configuration.a

    assert_equal here, there
  end

  def with_gc_disabled(&_block)
    GC.disable
    yield
    GC.enable
  end
end
