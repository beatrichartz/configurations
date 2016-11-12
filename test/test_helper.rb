require 'simplecov'
SimpleCov.start

require 'pathname'
require 'minitest'

PATH = Pathname.new(File.dirname(__FILE__))

$LOAD_PATH.unshift PATH, File.expand_path('../../lib', __FILE__)
require 'configurations'

Dir[PATH.join('support', '**', '*.rb')].each(&method(:require))
Dir[PATH.join('configurations', 'shared', '*.rb')].each(&method(:require))

class ConfigurationsTest < Minitest::Test
  include Test::Support::Setup
  extend Test::Support::Shared
end

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/focus'
require 'test/unit/assertions'
