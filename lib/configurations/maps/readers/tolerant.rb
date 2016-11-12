module Configurations
  module Maps
    module Readers
      class Tolerant
        def read(map, path)
          path.reduce(map) do |m, value|
            m[value] if m
          end
        end
      end
    end
  end
end
