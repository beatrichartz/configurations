module Tests
  module Shared
    module StrictHashMethods
      def test_from_h
        expected, input = expection_and_input
        assert_equal(expected, @module.configure { |c| c.from_h(input) }.to_h)
      end

      def test_from_h_with_strings
        expected, input = expection_and_input
        string_input = Hash[input.map { |k, v| [k.to_s, v] }]
        assert_equal(
          expected,
          @module.configure { |c| c.from_h(string_input) }.to_h
        )
      end

      def test_from_h_outside_block
        expected, input = expection_and_input
        assert_equal(expected, @configuration.from_h(input).to_h)
      end

      private

      def expection_and_input
        old_to_h = @configuration.to_h.dup
        expected = deep_dup(old_to_h)

        old_to_h[:p3][:p5][:p6].reverse!
        expected[:puts] = Class

        [expected, old_to_h]
      end

      def deep_dup(h)
        h.reduce({}) do |hash, (k, v)|
          hash[k] = if v.is_a?(Hash)
                      deep_dup(v)
                    else
                      begin
                        v.dup
                      rescue TypeError
                        v
                      end
                    end

          hash
        end
      end
    end
  end
end
