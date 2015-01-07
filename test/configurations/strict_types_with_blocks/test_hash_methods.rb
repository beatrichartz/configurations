require 'test_helper'

class TestHashMethodsOnStrictTypesWithBlocks < ConfigurationsTest
  shares_tests :hash_methods, :strict_hash_methods
  setup_with :strict_types_with_blocks do |c|
    c.p1 = 'CONFIGURED P1'
    c.p2 = -2
    c.p3.p4 = 'CONFIGURED P3P4'
    c.p3.p5.p6 = %w(P6 P5 P3)
    c.p3.p5.p7 = { config: 'hash' }
    c.class = :class
    c.puts = Class
  end
end
