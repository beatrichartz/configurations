$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'configurations'

Gem::Specification.new do |s|
  s.name              = 'configurations'
  s.version           = Configurations::VERSION
  s.authors           = ['Beat Richartz']
  s.description       = 'Configurations provides several ways to configure your gem or ruby application: Arbitrary, strict or standard'
  s.email             = 'attr_accessor@gmail.com'
  s.homepage          = 'http://github.com/beatrichartz/zombies'
  s.licenses          = %w(MIT)
  s.require_paths     = %w(lib)
  s.summary           = 'Configuration patterns for your code'

  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- spec/*`.split("\n")

  s.add_development_dependency 'minitest', '~> 5.4'
end
