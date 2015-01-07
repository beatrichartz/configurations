module Test
  module Support
    module Shared
      def shares_tests(*tests)
        tests.each do |test|
          include Tests::Shared.const_get(test.to_s.split('_').map(&:capitalize).join)
        end
      end
    end
  end
end
