
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
