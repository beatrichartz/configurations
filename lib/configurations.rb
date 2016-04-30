require_relative 'configurations/arbitrary'
require_relative 'configurations/arbitrary_configurable_tester'
require_relative 'configurations/blank_object'
require_relative 'configurations/configurable'
require_relative 'configurations/configuration'
require_relative 'configurations/data'
require_relative 'configurations/error'
require_relative 'configurations/key_ambiguity_tester'
require_relative 'configurations/reserved_method_tester'
require_relative 'configurations/strict'
require_relative 'configurations/strict_configurable_tester'

# Configurations provides a unified approach to do configurations
# with the flexibility to do everything from arbitrary configurations
# to type asserted configurations for your gem or any other ruby code.
# @version 2.0.0
# @author Beat Richartz
#
module Configurations
  extend Configurable

  # Version number of Configurations
  #
  VERSION = '2.2.0'
end
