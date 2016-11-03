# Configurations
[![Build Status](https://travis-ci.org/beatrichartz/configurations.svg?branch=master)](https://travis-ci.org/beatrichartz/configurations) [![Test Coverage](https://codeclimate.com/github/beatrichartz/configurations/badges/coverage.svg)](https://codeclimate.com/github/beatrichartz/configurations) [![Code Climate](https://codeclimate.com/github/beatrichartz/configurations/badges/gpa.svg)](https://codeclimate.com/github/beatrichartz/configurations) [![Inline docs](http://inch-ci.org/github/beatrichartz/configurations.svg?branch=master)](http://inch-ci.org/github/beatrichartz/configurations) [![Dependency Status](https://gemnasium.com/beatrichartz/configurations.svg)](https://gemnasium.com/beatrichartz/configurations)


Configurations provides a unified approach to do configurations using the `MyGem.configure do ... end` idiom with the flexibility to do everything from arbitrary configurations to type asserted configurations for your gem or any other ruby code.

## Install

```ruby
gem install configurations
```

or with Bundler

```ruby
gem 'configurations', '~> 2.2.0'
```

Configurations uses [Semver 2.0](http://semver.org/)

## Compatibility

Compatible with MRI 1.9.2 - 2.2, Rubinius 2.x, jRuby 1.7 and 9K

## Why?

There are various ways to do configurations, yet there seems to be a broad consensus on the `MyGem.configure do ... end` idiom.
So instead of rolling your own, you can add this gem to your gem and get that functionality for free, plus some goodies you may want
but do not have the time to write like type assertion or nested configurations.

Less time copy pasting configuration code, more time writing exciting code for you.

## Configure

### First way: Arbitrary Configuration

Go boom! with ease. This allows your gem / code users to set any value they like.

```ruby
module MyGem
  include Configurations
end
```

Gives your users:

```ruby
MyGem.configure do |c|
  c.foo.bar.baz = 'fizz'
  c.hi = 'Hello-o'
  c.class = 'oooh wow' # Such flexible!
end
```

Gives you:

```ruby
MyGem.configuration.class #=> 'oooh wow'
MyGem.configuration.foo.bar.baz #=> 'fizz'
```

Undefined properties on an arbitrary configuration will return `nil`

```ruby
MyGem.configuration.not_set #=> nil
```

If you want to define the behaviour for not set properties yourself, use `not_configured`. You can either define a catch-all `not_configured` which will be executed whenever you call a value that has not been configured and has no default:

```ruby
module MyGem
  not_configured do |prop|
	raise NoMethodError, "#{prop} must be configured"
  end
end
```

Or you can define finer-grained callbacks:

```ruby
module MyGem
  not_configured my: { nested: :prop } do |prop|
	raise NoMethodError, "#{prop} must be configured"
  end
end
```

### Second way: Restricted Configuration

If you just want some properties to be configurable, consider this option

```ruby
module MyGem
  include Configurations
  configurable :foo, bar: :baz, biz: %i(bi ba bu)
end
```

Gives your users:

```ruby
MyGem.configure do |c|
  c.foo = 'FOO'
  c.bar.baz = 'FIZZ'
  c.biz.bi = 'BI'
  c.biz.ba = 'BA'

  # This would raise NoMethodError
  # c.bar.biz
end
```

Gives you:

```ruby
MyGem.configuration.foo #=> 'FOO'
MyGem.configuration.bar.baz #=> 'FIZZ'
```

Not configured properties on a restricted configuration will raise `NoMethodError`

```ruby
MyGem.configuration.not_set #=> <#NoMethodError>
```

If you want to define the behaviour for not set properties yourself, use `not_configured`. This will only affect properties set to configurable. All not configurable properties will raise `NoMethodError`.

```ruby
module MyGem
  not_configured :awesome, :nice do |prop| # omit the arguments to get a catch-all not_configured
	warn :not_configured, "Please configure #{prop} or live in danger: youtube.com/watch?v=yZ15vCGuvH0"
  end
end
```

### Third way: Type Restricted Configuration

If you want to make sure your configurations only accept one type, consider this option

```ruby
module MyGem
  include Configurations
  configurable String, :foo
  configurable Array, bar: :baz
end
```

Gives your users:

```ruby
MyGem.configure do |c|
  c.foo = 'FOO'
  c.bar.baz = %w(hello)

  # This would raise Configurations::ConfigurationError
  # c.foo = :not_so_foo
  # c.bar.baz = 'oh my cannot configure'
end
```

### Fourth way: Custom asserted or changed values

If you need further assertions or you need to change a value before it gets stored in the configuration, consider passing a block

```ruby
module MyGem
  include Configurations
  configurable :foo do |value|

	# The return value is what gets assigned, unless it is nil,
	# in which case the original value persists
	#
	value + ' ooooh my'
  end
  configurable String, bar: :baz do |value|

	# value is guaranteed to be a string at this point
	#
	unless %w(bi ba bu).include?(value)
	  raise ArgumentError, 'baz needs to be one of bi, ba, bu'
	end
  end
end
```

Gives your users:

```ruby
MyGem.configure do |c|
  c.foo = 'FOO'
  c.bar.baz = %w(bi)

  # This would raise the ArgumentError in the block
  # c.bar.baz = %w(boooh)
end
```

Gives you:

```ruby
MyGem.configuration.foo #=> 'FOO ooooh my'
MyGem.configuration.bar.baz #=> one of %w(bi ba bu)
```

### Configuration Methods

You might want to define methods on your configuration which use configuration values to bring out another value.
This is what `configuration_method` is here to help you with:

```ruby
module MyGem
  include Configurations
  configurable :foo, :bar
  configuration_method :foobar do |arg|
	foo + bar + arg
  end
end
```

Your users do:

```ruby
MyGem.configure do |c|
  c.foo = 'FOO'
  c.bar = 'BAR'
end
```

You get:

```ruby
MyGem.configuration.foobar('ARG') #=> 'FOOBARARG'
```

configuration methods can also be installed on nested properties using hashes:

```ruby
configuration_method foo: :bar do |arg|
  foo + bar + arg
end
```

### Defaults:

```ruby
module MyGem
  include Configurations
  configuration_defaults do |c|
	c.foo.bar.baz = 'BAR'
  end
end
```

### Get a hash if you need it

```ruby
MyGem.configuration.to_h #=> a Hash
```

### Configure with a hash where needed

Sometimes your users will have a hash of configuration values which are not handy to press into the block form. In that case, they can use `from_h` inside the `configure` block to either read in the full or a nested configuration. With a everything besides arbitrary configurations, `from_h` can also be used outside the block.

```ruby
yaml_hash = YAML.load_file('configuration.yml')

MyGem.configure do |c|
  c.foo = 'bar'
  c.baz.from_h(yaml_hash)
end
```

### Some caveats

#### Reserved Methods
These are reserved methods on the configuration instance and should not be defined:
- `initialize`
- `inspect`
- `method_missing`
- `object_id`
- `singleton_class`
- `to_h`
- `to_s`

`Configuration` inherits from `BasicObject`, so method names defined through `Kernel` and `Object` are available.

## Thread safety
Configuration is synchronized. Re-configuration via the `configure` block switches out the configuration in place rather than mutating its properties, so don't hold on to configuration objects in another context.
That said, please bear in mind that keeping mutable state in configurations is as bad an idea as every other kind of global mutable state, if you expect values to change at runtime, configurations are not the right place to keep them:

Encourage your users to configure once when initializing the environment, reconfigure on reload, but never ever at runtime.

## Contributing

YES!

Let's make this awesome. Write tests for your added stuff, bonus points for feature branches. If you don't have the time to write a fix, raise an issue.

### Copyright

Copyright © 2015 Beat Richartz. See LICENSE.txt for further details.
