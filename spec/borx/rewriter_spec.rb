
describe Borx::Rewriter do

  def rewrite(*args)
    Borx::Rewriter.rewrite(*args)
  end

  it "redirects constant get" do
    expect( rewrite("X") ).to eql Borx::Code.new('__borx__.get_constant(binding, "X")')
  end

  it "redirects nested constant get" do
    expect( rewrite("X::Y") ).to eql Borx::Code.new('__borx__.get_constant(binding, "Y", __borx__.get_constant(binding, "X"))')
  end

  it "redirects global constant get" do
    expect( rewrite("::X") ).to eql Borx::Code.new('__borx__.get_constant(binding, "X", Object)')
  end

  it "redirects constant set" do
    expect( rewrite("X=1") ).to eql Borx::Code.new('__borx__.set_constant(binding, "X", 1)')
  end

  it "redirects nested constant set" do
    expect( rewrite("X::Y=1") ).to eql Borx::Code.new('__borx__.set_constant(binding, "Y", __borx__.get_constant(binding, "X"), 1)')
  end

  it "redirects global constant set" do
    expect( rewrite("::X=1") ).to eql Borx::Code.new('__borx__.set_constant(binding, "X", Object, 1)')
  end

  it "redirects simple method calls" do
    expect( rewrite("x.y(1)") ).to eql Borx::Code.new('__borx__.call_method(binding, __borx__.get_variable(binding, "x"), "y", 1)')
  end

  it "redirects setter method calls" do
    expect( rewrite("x.y=1") ).to eql Borx::Code.new('__borx__.call_method(binding, __borx__.get_variable(binding, "x"), "y=", 1)')
  end

  it "redirects method calls with blocks" do
    expect( rewrite("x.y{|a|a}") ).to eql Borx::Code.new('__borx__.call_method(binding, __borx__.get_variable(binding, "x"), "y") { |a| __borx__.get_variable(binding, "a") }')
  end

  it "redirects method private calls with blocks" do
    expect( rewrite("y{|a|a}") ).to eql Borx::Code.new('__borx__.call_private_method(binding, self, "y") { |a| __borx__.get_variable(binding, "a") }')
  end

  it "redirects variable sets" do
    expect( rewrite("x=1") ).to eql Borx::Code.new('__borx__.set_variable(binding, "x", 1)')
  end

  it "redirects __FILE__" do
    expect( rewrite("__FILE__") ).to eql Borx::Code.new('__borx__.get_magic(binding, "__FILE__")')
  end

  it "redirects xstrings" do
    expect( rewrite('`x`') ).to eql Borx::Code.new('__borx__.execute(binding, "x")')
  end
end
