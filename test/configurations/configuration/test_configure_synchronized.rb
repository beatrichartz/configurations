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
    semaphore = Mutex.new
    threads = 100.times.map do |i|
      Thread.new do
        sleep i%5 / 1000.0
        value = TestModuleA.configure do |c|
          c.a = i
        end.a

        semaphore.synchronize { collector << value }
      end
    end
    threads.each(&:join)

    assert_equal 100, collector.uniq.size
  end

  class SyncTime
    class << self
      @@semaphore = Mutex.new
      def now
        @@semaphore.synchronize do
          ("%0.8f" % Time.now.to_f).to_f
        end
      end
    end
  end

  class WriteSequence
    attr_reader :list

    class Linked
      attr_accessor :next
      attr_reader :time, :value
      def initialize(time, value)
        @time = time
        @value = value
      end
    end

    class Builder
      attr_reader :semaphore, :values
      private :semaphore, :values

      def initialize
        @values = []
        @semaphore = Mutex.new
      end
      def add(value)
        semaphore.synchronize do
          values << [SyncTime.now, value]
        end
      end

      def list
        v = values.sort_by(&:first)
        list = Linked.new(*v.shift)
        v.reduce(list) { |l, (t, value)|
          l.next = Linked.new(t, value)
        }
        list
      end
    end

    class << self
      private :new
    end

    def self.build
      builder = Builder.new
      yield(builder)
      new(builder.list)
    end

    def initialize(list)
      @list = list
    end

    def assert_valid_read(read_time, read_value)
      write = list
      last_write = write
      # read before any write
      if read_value == -1 && write.time >= read_time
        return
      # read of default value after first write
      elsif read_value == -1
        raise_invalid_read!(
          read_time,
          read_value,
          write.time,
          write.value
        )
      end

      loop do
        # safety catch: read not found in writes
        if write.nil?
          raise_invalid_read!(read_time, read_value, last_write.time, last_write.value)
        end

        next_write = write.next

        # valid read
        if write.value == read_value
          if write.time <= read_time &&
            (next_write.nil? || next_write.time >= read_time)
          break
          end
        end

        # stale read
        if write.value != read_value &&
            write.time < read_time &&
            (next_write.nil? || next_write.time > read_time)
          raise_invalid_read!(read_time, read_value, write.time, write.value)
        end

        last_write = write
        write = write.next
      end
    end

    private

    def raise_invalid_read!(time, value, valid_time, valid_value)
      raise "Invalid read: time: #{time.inspect}, value: #{value.inspect}. \
Valid read would have been #{valid_value.inspect} (written at #{valid_time.inspect}). \
Time difference: #{valid_time - time}"
    end
  end

  class ReadSequence
    extend Forwardable
    attr_reader :values, :semaphore
    private :values
    def_delegators :values, :each

    def initialize
      @values = []
      @semaphore = Mutex.new
    end

    def add(value)
      semaphore.synchronize do
        @values << [SyncTime.now, value]
      end
    end
  end

  def test_serializable
    reads = ReadSequence.new
    writes = WriteSequence.build do |w|
      threads = 500.times.flat_map do |i|
        [
          Thread.new do
            sleep 0.001
            TestModuleB.configure do |c|
              c.a = i
              w.add(i)
            end
          end,
          Thread.new do
            sleep 0.001
            reads.add(TestModuleB.configuration.a)
          end
        ]
      end
      threads.each(&:join)
    end

    reads.each{ |(t, v)| writes.assert_valid_read(t, v) }
  end

end
