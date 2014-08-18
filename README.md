# Configurations
[![Build Status](https://travis-ci.org/beatrichartz/configurations.svg?branch=master)](https://travis-ci.org/beatrichartz/configurations) [![Test Coverage](https://codeclimate.com/github/beatrichartz/configurations/badges/coverage.svg)](https://codeclimate.com/github/beatrichartz/configurations) [![Code Climate](https://codeclimate.com/github/beatrichartz/configurations/badges/gpa.svg)](https://codeclimate.com/github/beatrichartz/configurations) [![Inline docs](http://inch-ci.org/github/beatrichartz/configurations.png?branch=master)](http://inch-ci.org/github/beatrichartz/configurations) [![Dependency Status](https://gemnasium.com/beatrichartz/configurations.svg)](https://gemnasium.com/beatrichartz/configurations)


Configurations provides a unified approach to do configurations using the `MyGem.configure do ... end` idiom with the flexibility to do everything from arbitrary configurations to type asserted configurations for your gem or any other ruby code.

## Install

`gem install configurations`

or with Bundler

`gem 'configurations', '~> 1.3.0'`

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

### Fourth way: Custom asserted or changed values

If you need further assertions or you need to change a value before it gets stored in the configuration, consider passing a block

```
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

```
MyGem.configure do |c|
  c.foo = 'FOO'
  c.bar.baz = %w(bi)

  # This would raise the ArgumentError in the block
  # c.bar.baz = %w(boooh)
end
```

Gives you:

```
MyGem.configuration.foo #=> 'FOO ooooh my'
MyGem.configuration.bar.baz #=> one of %w(bi ba bu)
```

### Configuration Methods

You might want to define methods on your configuration which use configuration values to bring out another value.
This is what `configuration_method` is here to help you with:

```
module MyGem
  include Configurations
  configurable :foo, :bar
  configuration_method :foobar do |arg|
    foo + bar + arg
  end
end
```

Your users do:

```
MyGem.configure do |c|
  c.foo = 'FOO'
  c.bar = 'BAR'
end
```

You get:

```
MyGem.configuration.foobar('ARG') #=> 'FOOBARARG'
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

The `to_h` from above is along with `method_missing`, `object_id` and `initialize` the only purposely defined API method which you can not overwrite with a configuration value.
Apart from these methods, you should be able to set pretty much any property name you like. `Configuration` inherits from `BasicObject`, so even `Kernel` and `Object` method names are available.

## Contributing

YES!

Let's make this awesome. Write tests for your added stuff, bonus points for feature branches. If you don't have the time to write a fix, raise an issue.

### Copyright

Copyright © 2014 Beat Richartz. See LICENSE.txt for further details.
