require 'borx/binding'

base = Class.new do

  def get_constant(binding, name, house = nil)
    raise Borx::Environment::NotImplemented::GetConstant
  end

  def set_constant(binding, name, house = nil, value)
    raise Borx::Environment::NotImplemented::SetConstant
  end

  def call_method(binding, receiver, name, *args, &block)
    raise Borx::Environment::NotImplemented::CallMethod
  end

  def get_variable(binding, name)
    raise Borx::Environment::NotImplemented::GetVariable
  end

  def set_variable(binding, name, value)
    raise Borx::Environment::NotImplemented::SetVariable
  end

  def get_magic(binding, name, actual)
    raise Borx::Environment::NotImplemented::GetMagic
  end

  # @!method eval(code, binding = nil, file = 'borx', line = 0)
  #   @param [String, Borx::Code] code
  #   @param [Binding, Borx::Binding, nil] binding
  #   @param [String] file
  #   @param [Numeric] line
  #
  # @!method eval(code, options = {})
  #   @param [String, Borx::Code] code
  #   @param [Hash] options
  #   @option options [Binding, Borx::Binding] :binding
  #   @option options [Object] :self main object, only used when no binding is given
  #   @option options [String] :file
  #   @option options [Numeric] :line
  #   
  def eval(code, opts_or_binding = nil, file = 'borx', line = 0)
    bindink = opts_or_binding
    case(opts_or_binding)
    when nil then
      bindink = proc{}.binding
    when Hash then
      opts = opts_or_binding
      if opts[:binding]
        bindink = opts[:binding]
      elsif opts[:self]
        bindink = opts[:self].instance_eval{ binding }
      else
        bindink = proc{}.binding
      end
      file = opts[:file] || 'borx'
      line = opts[:line] || 0
    when Borx::Binding, ::Binding then
      bindink = opts_or_binding
    else
      raise ArgumentException, "Expected a Hash or a Binding, got #{opts_or_binding.inspect}"
    end
    eval_code( Borx::Rewriter.rewrite(code), bindink, file, line)
  end

private

  def eval_code(code, binding, file, line)
    old_borx, setter = binding.eval('__borx__ ||= nil ; __borx_binding__ = Borx::Binding(binding) ; [__borx__, lambda{|v| __borx__ = v}]')
    setter.call(self)
    binding.eval(code.code, file, line)
  ensure
    setter.call(old_borx) if setter
  end

end

class Borx::Environment < base

  Base = superclass

  module GetVariable

    def get_variable(binding, name)
      binding.get_variable(name)
    end

  end

  module SetVariable

    def set_variable(binding, name, value)
      binding.set_variable(name,value)
    end

  end

  module GetSetVariable
    include GetVariable
    include SetVariable
  end

  module CallPublicMethod
    def call_method(binding, receiver, name ,*args, &block)
      receiver.__send__(name, *args, &block)
    end
  end

  module CallPrivateMethod
    def call_private_method(binding, receiver, name ,*args, &block)
      receiver.__send__(name, *args, &block)
    end
  end

  module CallMethod
    include CallPublicMethod
    include CallPrivateMethod
  end

  module GetConstant
    def get_constant(binding, name, house = Object)
      house.const_get(name)
    end
  end

  module GetSetConstant
    include GetConstant
  end

  module GetMagic
    def get_magic(_binding, _name, actual)
      return actual
    end
  end

  include GetSetVariable
  include GetSetConstant
  include CallMethod
  include GetMagic

  class NotImplemented < StandardError
    class GetConstant < self
    end
    class SetConstant < self
    end
    class CallMethod < self
    end
    class GetVariable < self
    end
    class SetVariable < self
    end
    class GetMagic < self
    end
  end

end
