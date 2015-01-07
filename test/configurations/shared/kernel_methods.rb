module Tests
  module Shared
    module KernelMethods
      def test_respond_to_kernel_method
        assert_respond_to @configuration, :fail
      end
    end
  end
end
