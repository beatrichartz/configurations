module Configurations
  module Validators
    class Ambiguity
      # @param [Hash] the hash to test for ambiguity
      # @raise [Configurations::ConfigurationError] raises this error if
      #    a property is defined ambiguously
      #
      def validate!(h)
        symbols, others = h.keys.partition { |k|
          k.is_a?(::Symbol)
        }

        ambiguous = symbols.map(&:to_s) & others

        unless ambiguous.empty?
          ::Kernel.fail(
            ::Configurations::ConfigurationError,
            "Can not resolve configuration values for #{ambiguous.join(', ')} " \
            "defined as both Symbol and #{others.first.class.name} keys. " \
            'Please resolve the ambiguity.'
          )
        end
      end
    end
  end
end
