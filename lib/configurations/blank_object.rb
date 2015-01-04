module Configurations

  # Create a blank object with some kernel methods
  #
  class BlankObject < ::BasicObject
    OBJECT_METHODS  = [:equal?, :__id__, :__send__, :method_missing].freeze

    ALIASED_KERNEL_METHODS = {__class__: :class, __instance_eval__: :instance_eval, __define_singleton_method__: :define_singleton_method}.freeze
    KERNEL_METHODS  = [:respond_to?, :is_a?, :kind_of?, :inspect, :object_id].freeze

    (::BasicObject.instance_methods - OBJECT_METHODS).each do |method|
      undef_method method
    end

    kernel = ::Kernel.dup
    ALIASED_KERNEL_METHODS.each do |new_name, old_name|
      kernel.module_eval { alias_method new_name, old_name }
    end
    (kernel.instance_methods - (KERNEL_METHODS + ALIASED_KERNEL_METHODS.keys)).each do |method|
      kernel.__send__ :undef_method, method
    end
    include kernel
  end

end
