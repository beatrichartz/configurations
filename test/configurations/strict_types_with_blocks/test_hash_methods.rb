require 'test_helper'

class TestHashMethodsOnStrictTypesWithBlocks < ConfigurationsTest

  shares_tests :hash_methods
  setup_with :strict_types_with_blocks do |c|
    c.p1 = 'CONFIGURED P1'
    c.p2 = -2
    c.p3.p4 = 'CONFIGURED P3P4'
    c.p3.p5.p6 = %w(P6 P5 P3)
    c.p3.p5.p7 = { config: 'hash' }
    c.class = :class
    c.puts = Class
  end

  def test_from_h
    old_to_h = @configuration.to_h.dup
    expected = deep_dup(old_to_h)

    old_to_h[:p3][:p5][:p6].reverse!
    expected[:puts] = Class

    assert_equal(expected, @module.configure{ |c| c.from_h(old_to_h) }.to_h)
  end

  def test_from_h_outside_block
    old_to_h = @configuration.to_h.dup
    assert_equal(old_to_h, @configuration.from_h(old_to_h).to_h)
  end

  private

  def deep_dup(h)
    h.reduce({}) do |hash, (k,v)|
      hash[k] = if v.is_a?(Hash)
                  deep_dup(v)
                else
                  begin
                    v.dup
                  rescue TypeError
                    v
                  end
                end

      hash
    end
  end
end
