require 'test_helper'

class TestConfigurationSynchronized < MiniTest::Test
  module TestModuleA
    include Configurations

    configuration_defaults do |c|
      c.a = -1
    end
  end

  module TestModuleB
    include Configurations

    configuration_defaults do |c|
      c.a = -1
    end
  end

  def test_configuration_synchronized
    collector = []
    threads = 100.times.map do |i|
      Thread.new do
        sleep i%50 / 1000.0
        collector << TestModuleA.configure do |c|
          c.a = i
        end.a
      end
    end
    threads.each(&:join)

    assert_equal 100, collector.uniq.size
  end

end
