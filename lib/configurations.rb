require_relative 'configurations/error'
require_relative 'configurations/blank_object'
require_relative 'configurations/configuration'
require_relative 'configurations/arbitrary'
require_relative 'configurations/strict'
require_relative 'configurations/configurable'

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
  VERSION = '2.1.1'
end
