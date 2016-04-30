module Configurations
  class ReservedMethodTester
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

    # @param [Symbol] method the method to test for reservedness
    # @raise [Configurations::ReservedMethodError] raises this error if
    #    a property is a reserved method.
    #
    def test_reserved!(method)
      ::Kernel.fail(
        ::Configurations::ReservedMethodError,
        "#{method} is a reserved method and can not be assigned"
      ) if reserved?(method)
    end
  end
end
