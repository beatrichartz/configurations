module Test
  module Support
    module Setup
      def self.included(base)
        base.instance_eval do
          def self.inherited(child)
            super

            child.extend ClassMethods
            child.send :include, InstanceMethods
            child.class_eval <<-CODE
              module TestModule
                include Configurations
              end
            CODE
          end
        end
      end

      module ClassMethods
        attr_writer :configuration_block

        class ContextClass
          attr_reader :props
          def initialize(*props)
            @props = props
          end
        end

        def configuration_block
          @configuration_block ||= lambda do |c|
            c.p1 = 'CONFIGURED P1'
            c.p2 = 2
            c.p3.p4 = 'CONFIGURED P3P4'
            c.p3.p5.p6 = %w(P3 P5 P6)
            c.p3.p5.p7 = { config: 'hash' }
            c.class = :class
            c.module = ->(a) { a }
            c.puts = Class
          end
        end

        def setup_with(*features, &block)
          mod = const_get(:TestModule)

          features.each do |feature|
            method = method(feature)
            mod.module_eval { |m| method.call(m) }
          end

          @configuration_block = block if block_given?
        end

        def defaults(base)
          base.configuration_defaults do |c|
            c.p1 = 'P1'

            c.p3.p4 = 'P3 P4'
            c.p3.p5.p7 = { hash: :hash }

            c.module = -> { 'M' }
            c.class = :class
          end
        end

        def strict(base)
          base.configurable :p1, :p2, :class, :module, :puts, p3: [
            :p4, {
              p5: [
                :p6,
                :p7
              ]
            }
          ]
        end

        def strict_types(base)
          base.class_eval do
            configurable String, :p1
            configurable Fixnum, :p2
            configurable String, p3: :p4
            configurable Array, p3: { p5: :p6 }
            configurable Hash, p3: { p5: :p7 }
            configurable Symbol, :class
            configurable Proc, :module
            configurable Class, :puts
          end
        end

        def strict_with_blocks(base)
          base.class_eval do
            configurable :p2 do |value|
              value.abs
            end
            configurable p3: :p4 do |value|
              lambda { value }.call
            end
            configurable p3: { p5: :p6 } do |value|
              value.reverse
            end
            configurable :p1, :class, :module, :puts, p3: { p5: :p7 }
          end
        end

        def strict_types_with_blocks(base)
          base.class_eval do
            configurable String, :p1
            configurable Fixnum, :p2 do |value|
              value.abs
            end
            configurable String, p3: :p4 do |value|
              lambda { value }.call
            end
            configurable Array, p3: { p5: :p6 } do |value|
              value.reverse
            end
            configurable Hash, p3: { p5: :p7 }
            configurable Symbol, :class
            configurable Proc, :module
            configurable Module, :puts
          end
        end

        def methods(base)
          base.class_eval do
            configuration_method :method1 do
              ContextClass.new(p1, p2)
            end

            context = 'CONTEXT'
            configuration_method :method2 do
              context + p1.to_s
            end
            configuration_method :method3 do |arg|
              arg + p1.to_s
            end
            configuration_method :kernel_raise do
              fail NotImplementedError, 'KERNEL RAISE'
            end
            configuration_method p3: { p5: :combination } do
              { a: :b }.merge(p7)
            end
          end
        end

        def not_configured_callbacks(base)
          base.class_eval do
            not_configured :p1, :p2, :puts do |_prop|
              fail NotImplementedError
            end

            not_configured p3: { p5: [:p6, :p7] } do |_prop|
              fail NotImplementedError
            end
          end
        end

        def not_configured_default_callback(base)
          base.not_configured do |_prop|
            fail ArgumentError
          end
        end
      end

      module InstanceMethods
        def setup
          @module = self.class.const_get(:TestModule)
          @configuration = @module.configure(&self.class.configuration_block)
        end
      end
    end
  end
end
