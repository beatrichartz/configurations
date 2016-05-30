module Configurations
  class Path
    def initialize(path = [])
      @path = path
    end

    def add(*path)
      Path.new(@path + path)
    end

    def walk(map)
      @path.reduce(map) do |map, value|
        map[value] if map
      end
    end

    def to_s
      @path.join(".")
    end
    alias :inspect :to_s
    alias :print :to_s

  end
end
