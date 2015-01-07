module Tests
  module Shared
    module NotConfiguredCallbacks
      def self.included(base)
        base.setup_with :defaults, :not_configured_callbacks do |c|
          c.p2 = 23
          c.p3.p4 = 'CONFIGURED P3P4'

          c.module = -> { 'MODULE' }
        end
      end

      def test_configured_with_default
        assert_equal 'P1', @configuration.p1
      end

      def test_configured_with_overwritten_default
        assert_equal 23, @configuration.p2
      end

      def test_nested_configured_with_default
        assert_equal({ hash: :hash }, @configuration.p3.p5.p7)
      end

      def test_nested_configured_with_overwritten_default
        assert_equal 'CONFIGURED P3P4', @configuration.p3.p4
      end

      def test_not_configured
        assert_raises NotImplementedError do
          @configuration.puts
        end
      end

      def test_nested_not_configured
        assert_raises NotImplementedError do
          @configuration.p3.p5.p6
        end
      end
    end
  end
end
