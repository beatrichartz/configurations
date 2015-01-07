module Tests
  module Shared
    module Methods
      def self.included(base)
        base.setup_with :methods
      end

      def test_method
        assert_equal ['CONFIGURED P1', 2], @configuration.method1.props
      end

      def test_method_with_context
        assert_equal 'CONTEXTCONFIGURED P1', @configuration.method2
      end

      def test_method_with_arguments
        assert_equal 'ARGCONFIGURED P1', @configuration.method3('ARG')
      end

      def test_nested_method
        assert_equal({ a: :b, config: 'hash' }, @configuration.p3.p5.combination)
      end

      def test_kernel_methods
        assert_raises NotImplementedError do
          @configuration.kernel_raise
        end
      end
    end
  end
end
