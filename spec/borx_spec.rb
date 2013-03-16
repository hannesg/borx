
describe Borx do

  it "works" do
    env = Borx::Environment.new
    result = env.eval <<'CODE'
a = 1
b = a + 2
b
CODE
    expect(result).to eql 3
  end

  it "works with inner variables" do
    env = Borx::Environment.new
    result = env.eval <<'CODE'
a = 1
[1,2,3].map do |a|
  a * 2
end
CODE
    expect(result).to eql [2,4,6]
  end

  it "can call outside methods" do
    def foo(x)
      return x * 2
    end

    env = Borx::Environment.new
    result = env.eval <<'CODE', binding
foo "bar"
CODE

    expect(result).to eql "barbar"

  end

  it "can call outside methods in blocks" do
    def foo(x)
      return x * 2
    end

    env = Borx::Environment.new
    result = env.eval <<'CODE', binding
["bar"].map do |bar|
  foo bar
end
CODE

    expect(result).to eql ["barbar"]
  end

  it "works as advertised" do
    env = Borx::Environment.new
    def env.call_method(binding, receiver, method, *args, &block)
      if method == "+"
        super(binding, receiver, "-", *args, &block)
      else
        super
      end
    end
    expect( env.eval("1 + 1") ).to eql 0
  end

  it "has a __FILE__ default" do
    env = Borx::Environment.new
    expect( env.eval("__FILE__") ).to eql "borx"
  end

  it "allows setting __FILE__" do
    env = Borx::Environment.new
    expect( env.eval("__FILE__", binding, "foo") ).to eql "foo"
  end

  it "supports __FILE__" do
    env = Borx::Environment.new
    def env.get_magic(binding, name, actual)
      return "foo"
    end
    expect( env.eval("__FILE__") ).to eql "foo"
  end

  it "allows using a Borx::Binding as binding" do
    env = Borx::Environment.new
    bind = Borx::Binding::Terminal.new
    expect(env.eval("a = 1; b = 2; a + b")).to eql 3
  end

  it "handles self correctly when passed a self object" do
    object = Object.new
    env = Borx::Environment.new
    expect(env.eval("self", :self => object )).to eql object
  end

  it "handles self correctly when passed a binding" do
    env = Borx::Environment.new
    expect(env.eval("self", :binding => binding )).to eql self
  end

  describe "::Binding" do

    it "returns a terminal binding without args" do
      expect(Borx::Binding()).to be_a(Borx::Binding::Terminal)
    end

    it "returns an adapter when given a real binding" do
      expect(Borx::Binding(binding)).to be_a(Borx::Binding::Adapter)
    end

    it "passes bindings through" do
      bind = Borx::Binding()
      expect(Borx::Binding(bind)).to eql bind
    end

    it "raise an argument error otherwise" do
      expect{ Borx::Binding(Object.new) }.to raise_error(ArgumentError)
    end

  end

end

describe Borx::Code do

  it "works in a hash" do
    h = {}
    h[ Borx::Code.new('xy') ] = 1
    expect( h[ Borx::Code.new('xy') ] ).to eql 1
  end

  it "has a readable inspect" do
    expect( Borx::Code.new('xy').inspect ).to eql '#<Borx::Code "xy">'
  end

end
