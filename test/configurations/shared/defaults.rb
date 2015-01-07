module Tests
  module Shared
    module Defaults
      def self.included(base)
        base.setup_with :defaults do |c|
          c.p2 = 23

          c.p3.p4 = 'CONFIGURED P3P4'

          c.module = -> { 'MODULE' }
        end
      end

      def test_property
        assert_equal 23, @configuration.p2
      end

      def test_property_with_default
        assert_equal 'P1', @configuration.p1
      end

      def test_overwritten_property
        assert_equal 'MODULE', @configuration.module.call
      end

      def test_overwritten_nested_property
        assert_equal 'CONFIGURED P3P4', @configuration.p3.p4
      end

      def test_nested_property_with_default
        assert_equal({ hash: :hash }, @configuration.p3.p5.p7)
      end

      def test_keywords_defaults
        assert_equal :class, @configuration.class
      end

      def test_no_default_no_write
        assert_nil @configuration.puts
      end
    end
  end
end
