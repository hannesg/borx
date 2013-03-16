
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

end
