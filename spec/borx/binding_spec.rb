describe Borx::Binding do

  it "sets variables locally" do
    parent = double("parent binding")
    parent.should_receive(:variable?).with("a").and_return(false)
    bind = Borx::Binding.new(parent)
    bind.set_variable("a", 1)
    expect(bind.get_variable("a")).to eql 1
  end

  it "propagates variables to the outside" do
    parent = double("parent binding")
    parent.should_receive(:variable?).with("a").and_return(true)
    parent.should_receive(:set_variable).with("a",1).and_return(1)
    parent.should_receive(:get_variable).with("a").and_return(1)
    bind = Borx::Binding.new(parent)
    bind.set_variable("a", 1)
    expect(bind.get_variable("a")).to eql 1
  end

  it "hides outside variables" do
    parent = double("parent binding")
    bind = Borx::Binding.new(parent)
    bind.set_variable!("a", 2)
    expect(bind.get_variable("a")).to eql 2
  end

  it "hides outside variables while writing" do
    parent = double("parent binding")
    bind = Borx::Binding.new(parent)
    bind.set_variable!("a", 2)
    bind.set_variable("a", 3)
    expect(bind.get_variable("a")).to eql 3
  end

  it "can evaluate code" do
    parent = double("parent binding")
    bind = Borx::Binding.new(parent)
    expect(bind.eval("1 + 2")).to eql 3
  end

  it "supports binding wrapping" do
    parent = double("parent binding")
    bind = Borx::Binding.new(parent)
    expect(bind.eval("Borx::Binding(binding)")).to eql bind
  end

  describe Borx::Binding::Adapter do

    def adapt(binding)
      Borx::Binding::Adapter.new(binding)
    end

    it "correctly detects variables" do
      a = 1
      expect( adapt(binding).variable? "a" ).to eql true
      expect( adapt(binding).variable? "b" ).to eql false
    end

    it "correctly get variables" do
      a = 1
      expect( adapt(proc{}.binding).get_variable "a" ).to eql 1
    end

  end

end
