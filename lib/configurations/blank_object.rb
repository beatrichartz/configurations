module Configurations
  # Create a blank object with some kernel methods
  #
  class BlankObject < ::BasicObject
    # The instance methods to keep on the blank object.
    #
    KEEP_METHODS = [
      :equal?,
      :object_id,
      :__id__,
      :__instance_variables__,
      :__send__,
      :method_missing
    ].freeze

    # The kernel methods to alias to an internal name
    #
    ALIAS_KERNEL_METHODS = {
      __class__: :class,
      __instance_eval__: :instance_eval,
      __define_singleton_method__: :define_singleton_method
    }.freeze

    # The kernel methods to keep on the blank object
    #
    KEEP_KERNEL_METHODS  = [
      :respond_to?,
      :is_a?,
      :inspect,
      :to_s,
      :object_id,
      # rbx needs the singleton class to access singleton methods
      :singleton_class,
      # rbx needs its private methods
      :__instance_variable_defined_p__,
      :__instance_variable_get__,
      :__instance_variable_set__,
      :__instance_variable__,
      *ALIAS_KERNEL_METHODS.keys
    ].compact.freeze

    # Undefines every instance method except the kept methods
    #
    (instance_methods - KEEP_METHODS).each do |method|
      undef_method method
    end

    # @return [Module] A Kernel module with only the methods
    #   defined in KEEP_KERNEL_METHODS
    #
    def self.blank_kernel
      kernel = ::Kernel.dup

      ALIAS_KERNEL_METHODS.each do |new_name, old_name|
        kernel.module_eval { alias_method new_name, old_name }
      end

      (kernel.instance_methods - KEEP_KERNEL_METHODS).each do |method|
        kernel.module_eval { undef_method method }
      end

      kernel
    end

    include blank_kernel
  end
end
