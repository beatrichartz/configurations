module Configurations
  # A configuration Error, raised when configuration gets misconfigured
  #
  ConfigurationError = Class.new(ArgumentError)

  # A reserved method error, raised when configurable is used with
  # reserved methods
  #
  ReservedMethodError = Class.new(NameError)
end
