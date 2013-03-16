Borx
=====

[![Build
Status](https://travis-ci.org/hannesg/borx.png?branch=master)](https://travis-ci.org/hannesg/borx)
[![Coverage
Status](https://coveralls.io/repos/hannesg/borx/badge.png?branch=master)](https://coveralls.io/r/hannesg/borx)

*DISCLAIMER: if you think this plugin is about rock-hard security, you are
wrong*

This plugin parses a piece of ruby code with ripper, rewrites it a bit and
converts it back to ruby code.  This lets a central object decide what the code
is actually doing.

Usage
-----------------

Completly trivial:

    env = Borx::Environment.new
    env.eval("1 + 1") # => 2

Gets tricky:

    env = Borx::Environment.new
    def env.call_method(binding, receiver, method,*args, &block)
      if method == "+"
        super(binding, receiver, "-", *args, &block)
      else
        super
      end
    end
    env.eval("1 + 1") # => 0

When to use
----------------

Please use your brain before using this. Make sure the following points apply to
your situation:

  - You have to solve your problem by evaluting ruby code which interacts with
    the rest of your application e.g. because it's specified by a third party.
  - Completly integrating the ruby code is not an option e.g. because it *must*
    be user defined.
  - Completly jailing the ruby code is not an option either e.g. because it
    *must* interact with some of your code.
  - The code you evaluate is rather small and simple.
  - Performance is not an issue.
  - You generally trust the people sending you code (again, this is not about
    security!).
  - You think this solution is ugly as hell. If you don't think like this,
    you've probably not understood what this library does.

How to use
-------------------

The most interesting class for you is `Borx::Environment`. By overriding its
methods you can control the behavior of evaled code.

To simplify things you can either you `Borx::Environment` or
`Borx::Environment::Base` as superclass. The difference is that 
`Borx::Environment` contains useful default implementation for all methods 
mentioned below while `Borx::Environemnt::Base` does not. So use the earlier if 
you want the code to behave normally except for some cases and the later if you 
want to redefine the behavior from scratch.

### Example

Calling `my_method` instead of `your_method`:

    class MyEnv < Borx::Environment
      def call_method( binding, receiver, name, *args, &block )
        name = "my_method" if name == "your_method"
        super( binding, receiver, name, *args, &block)
      end
      def call_private_method( binding, receiver, name, *args, &block)
        name = "my_method" if name == "your_method"
        super( binding, receiver, name, *args, &block)
      end
    end

    MyEnv.new.eval("your_method") #=> calls my_method

### Overrideable methods

These methods are currently overrideable to control behaviour of evaled code:

  - `get_variable( binding, variable )`
  - `set_variable( binding, variable, value )`
  - `call_method( binding, receiver, method, *args, &block)`
  - `call_private_method( binding, receiver, method, *args, &block)` - same as 
above, but called in a private context
  - `get_constant( binding, name, namespace = Object)`
  - `set_constant( binding, name, namespace = Object, value)`
  - `get_magic( binding, name, real_value )` - used to get several "magic"
    values e.g. self, \_\_FILE\_\_, \_\_LINE\_\_
  - `execute( binding, code )` - handles backtick execution

More will follow.

### Helper Module

You don't have to reimplement all the above methods in order to get a working 
environment. If you want the local variable system to behave as usual you can 
simply include `Borx::Environment::GetSetVariable` in you environment. Helper 
modules so far are:

  - `Borx::Environment::GetVariable` - supplies `get_variable`
  - `Borx::Environment::SetVariable` - supplies `set_variable`
  - `Borx::Environment::GetSetVariable` - same as the two above together
  - `Borx::Environment::CallMethod` - supplies `call_method` and
    `call_private_method`
  - `Borx::Environment::GetMagic` - supplies `get_magic`

License
-------------------

Copyright (C) 2013 Hannes Georg

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
