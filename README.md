Borx
=====

*DISCLAIMER: if you think this plugin is about rock-hard security, you are wrong*

This plugin parses a piece of ruby code with ripper, rewrites it a bit and converts it back to ruby code.
This lets a central object decide what the code is actually doing.

Usage
-----------------

Completly trivial:

    env = Borx::Environment.new
    env.eval("1 + 1") # => 2

Gets tricky:

    env = Borx::Environment.new
    def env.call_method(binding, receiver, method, *args, &block)
      if method == "+"
        super(receiver, "-", *args, &block)
      else
        super
      end
    end
    env.eval("1 + 1") # => 0

When to use
----------------

Please use your brain before using this. Make sure the following points apply to your situation:

  - You have to solve your problem by evaluting ruby code which interacts with the rest of your application e.g. because it's specified by a third party.
  - Completly integrating the ruby code is not an option e.g. because it *must* be user defined.
  - Completly jailing the ruby code is not an option either e.g. because it *must* interact with some of your code.
  - The code you evaluate is rather small and simple.
  - Performance is not an issue.
  - You generally trust the people sending you code (again, this is not about security!).
  - You think this solution is ugly as hell. If you don't think like this, you've probably not understood what this library does.

