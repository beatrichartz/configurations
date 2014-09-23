require "bundler/setup"
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'pathname'
require 'minitest'

PATH = Pathname.new(File.dirname(__FILE__))

$LOAD_PATH.unshift PATH, File.expand_path('../../lib', __FILE__)

Dir[PATH.join('support', '**', '*.rb')].each(&method(:require))

Minitest::Test.class_eval do
  extend TestModules
end

require 'minitest/autorun'
require 'minitest/pride'
require 'test/unit/assertions'

require 'configurations'
