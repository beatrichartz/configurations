module Configurations
  module Validators
    class ReservedMethods
      # @param [Symbol] method the method to test for reservedness
      # @raise [Configurations::ReservedMethodError] raises this error if
      #    a property is a reserved method.
      #
      def validate!(method)
        ::Kernel.fail(
          ::Configurations::ReservedMethodError,
          "#{method} is a reserved method and can not be assigned"
        ) if reserved?(method)
      end

      private

      # Reserved methods are not assignable. They define behaviour needed for
      # the configuration object to work properly.
      #
      RESERVED_METHODS = [
        :initialize,
        :inspect,
        :method_missing,
        :object_id,
        :singleton_class, # needed by rbx
        :to_h,
        :to_s # needed by rbx / 1.9.3 for inspect
      ]

      # @param [Symbol] method the method to test for
      # @return [TrueClass, FalseClass] whether the method is reserved
      #
      def reserved?(method)
        RESERVED_METHODS.include?(method)
      end

    end
  end
end
