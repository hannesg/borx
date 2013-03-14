# A simple class to tell the difference between rewritten and raw code.
class Borx::Code

  attr :code

  def initialize(code)
    @code = code
  end

  def hash
    code.hash
  end

  def eql?(other)
    code.eql?(other.code)
  end

  def inspect
    "#<Borx::Code #{code.inspect}>"
  end

end
