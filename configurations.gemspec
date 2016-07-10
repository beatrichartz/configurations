$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'configurations'

Gem::Specification.new do |s|
  s.name              = 'configurations'
  s.version           = Configurations::VERSION
  s.authors           = ['Beat Richartz']
  s.description       = <<-DESCRIPTION
Configurations provides a unified approach to do configurations with the flexibility to do everything
 from arbitrary configurations to type asserted configurations for your gem or any other ruby code.
DESCRIPTION
  s.email             = 'attr_accessor@gmail.com'
  s.homepage          = 'http://github.com/beatrichartz/configurations'
  s.licenses          = %w(MIT)
  s.require_paths     = %w(lib)
  s.summary           = <<-SUMMARY
Configurations with a configure block from arbitrary to type-restricted for your gem or other ruby code.
SUMMARY
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- test/*`.split("\n")

  s.add_development_dependency 'minitest', '~> 5.4'
  s.add_development_dependency 'minitest-focus', '~> 1.1'
  s.add_development_dependency 'test-unit', '~> 3'
  s.add_development_dependency 'yard', '~> 0.8'
  s.add_development_dependency 'rake', '~> 10'
end
