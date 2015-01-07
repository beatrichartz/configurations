module Tests
  module Shared
    module HashMethods

      def self.included(base)
        base.setup_with do |c|
          c.p1 = 'CONFIGURED P1'
          c.p2 = 2
          c.p3.p4 = 'CONFIGURED P3P4'
          c.p3.p5.p6 = %w(P3 P5 P6)
          c.p3.p5.p7 = { config: 'hash' }
          c.class = :class
          c.puts = Class
        end
      end

      def test_to_h
        assert_equal({
                       p1: 'CONFIGURED P1',
                       p2: 2,
                       p3: {
                         p4: 'CONFIGURED P3P4',
                         p5: {
                           p6: %w(P3 P5 P6),
                           p7: {
                             config: 'hash'
                           }
                         }
                       },
                       class: :class,
                       puts: Class
                     }, @configuration.to_h)
      end

      def test_from_h
        old_to_h = @configuration.to_h.dup
        assert_equal(old_to_h, @module.configure{ |c| c.from_h(old_to_h) }.to_h)
      end

    end
  end
end
