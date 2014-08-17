require_relative 'configurations/error'
require_relative 'configurations/configuration'
require_relative 'configurations/configurable'

# Configurations provides a unified approach to do configurations with the flexibility to do everything
# from arbitrary configurations to type asserted configurations for your gem or any other ruby code.
# @version 1.0.0
# @author Beat Richartz
#
module Configurations
  extend Configurable

  # Version number of Configurations
  #
  VERSION = '1.2.0'
end
