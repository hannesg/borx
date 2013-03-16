
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

  def child
    Borx::Binding.new(self)
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
      return @binding.eval("defined? #{name}")
    end

  end

end
