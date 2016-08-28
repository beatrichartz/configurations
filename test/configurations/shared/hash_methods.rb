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
        assert_equal(old_to_h, @module.configure { |c| c.from_h(old_to_h) }.to_h)
      end

      def test_from_h_with_strings
        old_to_h = @configuration.to_h.dup
        string_to_h = Hash[old_to_h.map { |k, v| [k.to_s, v] }]
        assert_equal(old_to_h, @module.configure { |c| c.from_h(string_to_h) }.to_h)
      end

      def test_from_h_with_ambiguous_strings_and_symbols
        assert_raises Configurations::ConfigurationError do
          @module.configure { |c| c.from_h('p1' => 'bla', :p1 => 'blu') }
        end
      end

      def test_from_h_with_unambiguous_strings_and_symbols
        config = @module.configure { |c| c.from_h('p1' => 'bla', :p2 => 2) }
        assert_equal 2, config.p2
        assert_equal 'bla', config.p1
      end
    end
  end
end
