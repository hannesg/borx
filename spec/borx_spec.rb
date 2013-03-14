
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

end
