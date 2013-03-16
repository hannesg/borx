
describe Borx::Rewriter do

  def rewrite(*args)
    Borx::Rewriter.rewrite(*args)
  end

  def borx_head
    return '__borx_binding__ = binding; '
  end

  it "redirects constant get" do
    expect( rewrite("X") ).to eql Borx::Code.new('__borx__.get_constant(__borx_binding__, "X")')
  end

  it "redirects nested constant get" do
    expect( rewrite("X::Y") ).to eql Borx::Code.new('__borx__.get_constant(__borx_binding__, "Y", __borx__.get_constant(__borx_binding__, "X"))')
  end

  it "redirects global constant get" do
    expect( rewrite("::X") ).to eql Borx::Code.new('__borx__.get_constant(__borx_binding__, "X", Object)')
  end

  it "redirects constant set" do
    expect( rewrite("X=1") ).to eql Borx::Code.new('__borx__.set_constant(__borx_binding__, "X", 1)')
  end

  it "redirects nested constant set" do
    expect( rewrite("X::Y=1") ).to eql Borx::Code.new('__borx__.set_constant(__borx_binding__, "Y", __borx__.get_constant(__borx_binding__, "X"), 1)')
  end

  it "redirects global constant set" do
    expect( rewrite("::X=1") ).to eql Borx::Code.new('__borx__.set_constant(__borx_binding__, "X", Object, 1)')
  end

  it "redirects simple method calls" do
    expect( rewrite("x.y(1)") ).to eql Borx::Code.new('__borx__.call_method(__borx_binding__, __borx__.get_variable(__borx_binding__, "x"), "y", 1)')
  end

  it "redirects setter method calls" do
    expect( rewrite("x.y=1") ).to eql Borx::Code.new('__borx__.call_method(__borx_binding__, __borx__.get_variable(__borx_binding__, "x"), "y=", 1)')
  end

  it "redirects method calls with blocks" do
    expect( rewrite("x.y{|a|a}") ).to eql Borx::Code.new('__borx__.call_method(__borx_binding__, __borx__.get_variable(__borx_binding__, "x"), "y", &__borx_binding__.block("a") { |__borx_binding__| __borx__.get_variable(__borx_binding__, "a") })')
  end

  it "redirects method private calls with args" do
    expect( rewrite("x(1)") ).to eql Borx::Code.new('__borx__.call_private_method(__borx_binding__, self, "x", 1)')
  end

  it "redirects method private calls with blocks" do
    expect( rewrite("y{|a|a}") ).to eql Borx::Code.new('__borx__.call_private_method(__borx_binding__, self, "y", &__borx_binding__.block("a") { |__borx_binding__| __borx__.get_variable(__borx_binding__, "a") })')
  end

  it "redirects method calls with added blocks" do
    expect( rewrite("y(&a)") ).to eql Borx::Code.new('__borx__.call_private_method(__borx_binding__, self, "y", &__borx_binding__.block(&__borx__.get_variable(__borx_binding__, "a")))')
  end

  it "redirects variable sets" do
    expect( rewrite("x=1") ).to eql Borx::Code.new('__borx__.set_variable(__borx_binding__, "x", 1)')
  end

  it "redirects variable gets" do
    expect( rewrite("x=1; x") ).to eql Borx::Code.new('__borx__.set_variable(__borx_binding__, "x", 1); __borx__.get_variable(__borx_binding__, "x")')
  end

  it "redirects __FILE__" do
    expect( rewrite("__FILE__") ).to eql Borx::Code.new('__borx__.get_magic(__borx_binding__, "__FILE__")')
  end

  it "redirects xstrings" do
    expect( rewrite('`x`') ).to eql Borx::Code.new('__borx__.execute(__borx_binding__, "x")')
  end

  it "redirects operators" do
    expect( rewrite('1+1') ).to eql Borx::Code.new('__borx__.call_method(__borx_binding__, 1, "+", 1)')
  end
end
