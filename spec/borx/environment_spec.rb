
describe Borx::Environment do

  let(:env){ Borx::Environment.new }

  def bind(b)
    Borx::Binding::Adapter.new(b)
  end

  it "can fetch local variables" do
    a = 1
    expect( env.get_variable(bind(binding), "a") ).to eql 1
  end

  it "can introduce local variables" do
    b = bind(binding)
    expect(env.set_variable(b, "a", 2) ).to eql 2
    expect(env.get_variable(b,"a")).to eql 2
  end

  it "can set local variables" do
    a = 1
    expect(env.set_variable(bind(binding), "a", 2) ).to eql 2
    expect(a).to eql 2
  end

  it "can fetch constants" do
    expect( env.get_constant(bind(binding), "IO") ).to eql IO
  end

  it "can call methods" do
    receiver = double()
    receiver.should_receive(:foo).with('bar',1).once.and_return "foobar"
    expect( env.call_method(bind(binding), receiver, "foo", "bar", 1) ).to eql "foobar"
  end

  it "can call private methods" do
    receiver = double()
    receiver.should_receive(:foo).with('bar',1).once.and_return "foobar"
    expect( env.call_private_method(bind(binding), receiver, "foo", "bar", 1) ).to eql "foobar"
  end

  describe ".eval" do

    it "accepts a hash" do
      a = 3
      expect( env.eval("__FILE__ * a", :binding => binding, :file => 'bar') ).to eql "barbarbar"
    end

    it "accepts a self object in the hash" do
      object = double("self object")
      object.should_receive(:foo).and_return("bar")
      expect( env.eval("foo", :self => object) ).to eql "bar"
    end

    it "accepts a Borx::Binding as binding" do
      bind = Borx::Binding()
      bind.set_variable('a', 1)
      expect( env.eval("a", :binding => bind) ).to eql 1
    end

  end

end

describe Borx::Environment::Base do

  let(:base){ Borx::Environment::Base.new }

  def bind(b)
    Borx::Binding::Adapter.new(b)
  end

  it "has an eval method" do
    expect(base).to respond_to(:eval)
  end

  it "barfs when getting constants" do
    expect{base.get_constant(bind(binding), "A")}.to raise_error(Borx::Environment::NotImplemented)
  end

  it "barfs when setting constants" do
    expect{base.set_constant(bind(binding), "A", 1)}.to raise_error(Borx::Environment::NotImplemented)
  end

  it "barfs when getting variables" do
    expect{base.get_variable(bind(binding), "a")}.to raise_error(Borx::Environment::NotImplemented)
  end

  it "barfs when setting variables" do
    expect{base.set_variable(bind(binding), "a", 1)}.to raise_error(Borx::Environment::NotImplemented)
  end

  it "barfs when calling methods" do
    expect{base.call_method(bind(binding), double(), "meth")}.to raise_error(Borx::Environment::NotImplemented)
  end

  it "barfs when getting magic stuff" do
    expect{base.get_magic(bind(binding), "__FILE__", "bla")}.to raise_error(Borx::Environment::NotImplemented)
  end

end
