module Tests
  module Shared
    module PropertiesOutsideBlock
      def self.included(base)
        base.setup_with do |c|
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

      def test_respond_to_writer
        assert_respond_to @configuration, :p1=
      end

      def test_respond_to_nested_writer
        assert_respond_to @configuration.p3, :p4=
      end

      def test_not_respond_to_nested_configuration_writer
        refute_respond_to @configuration, :p3=
      end

      def test_set_property_outside_block
        @configuration.p1 = 'OUTSIDE BLOCK P1'
        assert_equal 'OUTSIDE BLOCK P1', @configuration.p1
      end

      def test_set_nested_property_outside_block
        @configuration.p3.p5.p6 = %w(OUTSIDE BLOCK P3 P5 P6)
        assert_equal %w(OUTSIDE BLOCK P3 P5 P6), @configuration.p3.p5.p6
      end
    end
  end
end
