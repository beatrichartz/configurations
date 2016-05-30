module Configurations
  class Path
    def initialize(path = [])
      @path = path
    end

    def add(*path)
      Path.new(@path + path)
    end

    def reduce(initial, &block)
      @path.reduce(initial, &block)
    end

    def to_s
      @path.join(".")
    end
    alias :inspect :to_s
    alias :print :to_s

  end
end
