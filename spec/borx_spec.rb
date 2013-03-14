
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

end
