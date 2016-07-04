module Configurations
  module Maps
    module Writers
      class Default

        def initialize(&block)
          @entry_block = block
        end

        def write(map, path, value)
          map[path.to_s] = @entry_block.call(value)
        end

      end
    end
  end
end
