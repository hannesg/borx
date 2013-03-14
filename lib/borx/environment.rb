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

end

class Borx::Environment < base

  Base = superclass

  module GetVariable

    def get_variable(binding, name)
      binding.eval(name)
    end

  end

  module SetVariable

    def set_variable(binding, name, value)
      binding.eval("#{name} = nil ; lambda{|_x| #{name} = _x}").call(value)
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

  include GetSetVariable
  include GetSetConstant
  include CallMethod

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
  end

  def eval(code, bin_ding = binding)
    eval_code( Borx::Rewriter.rewrite(code), bin_ding)
  end

private
  def eval_code(code, binding, file = '(eval)', line = 0)
    old_borx, setter = binding.eval('__borx__ ||= nil ; [__borx__, lambda{|v| __borx__ = v}]')
    setter.call(self)
    binding.eval(code.code, file, line)
  ensure
    setter.call(old_borx) if setter
  end

end
