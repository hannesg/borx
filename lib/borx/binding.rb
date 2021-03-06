
class Borx::Binding

  def initialize(parent)
    @variables = {}
    @parent = parent
  end

  def get_variable(name)
    return @variables.fetch(name){ @parent.get_variable(name) }
  end

  def set_variable(name, value)
    if variable?(name)
      if @variables.key?(name)
        @variables[name] = value
      else
        @parent.set_variable(name, value)
      end
    else
      @variables[name] = value
    end
    return value
  end

  def variable?(name)
    return @variables.key?(name) || @parent.variable?(name)
  end

  def set_variable!(name, value)
    @variables[name] = value
  end

  alias actual_binding binding

  def cached_actual_binding
    @actual_binding ||= actual_binding
  end

  def binding
    return self
  end

  def eval(code, *args)
    Kernel::eval(code, cached_actual_binding, *args)
  end

  def block(*args, &block)
    Block.new(self, args, block)
  end

  class Block
    def initialize(parent, names, block)
      @parent = parent
      @block = block
      @names = names
    end

    def to_proc
      return method(:call).to_proc
    end

    def call(*args, &block)
      b = Borx::Binding.new(@parent)
      @names.zip(args){|name, value| b.set_variable!(name, value) }
      @block.call(b)
    end

  end

  class Terminal < self

    def initialize
      @variables = {}
    end

    def get_variable(name)
      return @variables[name]
    end

    def set_variable(name, value)
      return @variables[name] = value
    end

    def variable?(name)
      return @variables.key?(name)
    end

    alias set_variable! set_variable

  end

  class Adapter < self

    def initialize(real_binding)
      @binding = real_binding
    end

    def get_variable(name)
      return @binding.eval(name)
    end

    def set_variable(name, value)
      @binding.eval("#{name} = nil ; lambda{|_v| #{name} = _v}").call(value)
      return value
    end

    def variable?(name)
      return @binding.eval("local_variables.any?{|v| v.to_s == #{name.inspect}}")
    end

    def eval(*args)
      @binding.eval(*args)
    end

  end

end
