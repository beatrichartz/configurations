# Configurations [![Test Coverage](https://codeclimate.com/github/beatrichartz/configurations/badges/coverage.svg)](https://codeclimate.com/github/beatrichartz/configurations) [![Code Climate](https://codeclimate.com/github/beatrichartz/configurations/badges/gpa.svg)](https://codeclimate.com/github/beatrichartz/configurations)

Configurations provides a unified approach to do configurations using the `MyGem.configure do ... end` idiom with the flexibility to do everything from arbitrary configurations to type asserted configurations for your gem or any other ruby code.

## Install

`gem install configurations`

or with Bundler

`gem 'configurations', '~> 1.0.0'`

Configurations uses [Semver 2.0](http://semver.org/)

## Compatibility

Compatible with MRI 1.9.2 - 2.1, Rubinius, jRuby

## Why?

There are various ways to do configurations, yet there seems to be a broad consensus on the `MyGem.configure do ... end` idiom.
So instead of rolling your own, you can add this gem to your gem and get that functionality for free, plus some goodies you may want
but do not have the time to write like type assertion or nested configurations.

Less time copy pasting configuration code, more time writing exciting code for you.

## Configure

### First way: Arbitrary Configuration

Go boom! with ease. This allows your gem / code users to set any value they like.

```
module MyGem
  include Configurations
end
```

Gives your users:

```
MyGem.configure do |c|
  c.foo.bar.baz = 'fizz'
  c.hi = 'Hello-o'
  c.class = 'oooh wow' # Such flexible!
end
```

Gives you:

```
MyGem.configuration.class #=> 'oooh wow'
MyGem.configuration.foo.bar.baz #=> 'fizz'
```

### Second way: Restricted Configuration

If you just want some properties to be configurable, consider this option

```
module MyGem
  include Configurations
  configurable :foo, bar: :baz, biz: %i(bi ba bu)
end
```

Gives your users:

```
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

```
MyGem.configuration.foo #=> 'FOO'
MyGem.configuration.bar.baz #=> 'FIZZ'
```

### Third way: Type Restricted Configuration

If you want to make sure your configurations only accept one type, consider this option

```
module MyGem
  include Configurations
  configurable String, :foo
  configurable Array, bar: :baz
end
```

Gives your users:

```
MyGem.configure do |c|
  c.foo = 'FOO'
  c.bar.baz = %w(hello)

  # This would raise Configurations::ConfigurationError
  # c.foo = :not_so_foo
  # c.bar.baz = 'oh my cannot configure'
end
```

Gives you:

```
MyGem.configuration.foo #=> 100% String
MyGem.configuration.bar.baz #=> 100% Array
```

### Defaults:

```
module MyGem
  include Configurations
  configuration_defaults do |c|
    c.foo.bar.baz = 'BAR'
  end
end
```

### Get a hash if you need it

```
MyGem.configuration.to_h #=> a Hash

```

### Some caveats

The `to_h` from above is along with `method_missing`, `object_id` and `initialize` the only purposely defined method which you can not overwrite with a configuration value.
Apart from these methods, you should be able to set pretty much any property name you like. `Configuration` inherits from `BasicObject`, so even standard Ruby method names are available.

## Contributing

YES!

Let's make this awesome. Write tests for your added stuff, bonus points for feature branches. If you don't have to time to write a fix, raise an issue.

### Copyright

Copyright © 2014 Beat Richartz. See LICENSE.txt for further details.
