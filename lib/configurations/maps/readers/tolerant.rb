module Configurations
  module Maps
    module Readers
      class Tolerant
        def read(map, path)
          path.reduce(map) do |map, value|
            map[value] if map
          end
        end
      end
    end
  end
end
