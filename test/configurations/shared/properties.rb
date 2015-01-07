module Tests
  module Shared
    module Properties
      def self.included(base)
        base.setup_with do |c|
          c.p1 = 'CONFIGURED P1'
          c.p2 = 2
          c.p3.p4 = 'CONFIGURED P3P4'
          c.p3.p5.p6 = %w(P3 P5 P6)
          c.p3.p5.p7 = { config: 'hash' }
          c.class = :class
          c.module = ->(a) { a }
          c.puts = Class
        end
      end

      def test_property
        assert_equal 'CONFIGURED P1', @configuration.p1
      end

      def test_nested_property
        assert_equal 'CONFIGURED P3P4', @configuration.p3.p4
      end

      def test_nested_hash_property
        assert_equal({ config: 'hash' }, @configuration.p3.p5.p7)
      end

      def test_keyword_property
        assert_equal :class, @configuration.class
      end

      def test_kernel_method_property
        assert_equal Class, @configuration.puts
      end

      def test_respond_to_property
        assert_respond_to @configuration, :p1
      end

      def test_respond_to_nested_property
        assert_respond_to @configuration.p3, :p4
      end
    end
  end
end
