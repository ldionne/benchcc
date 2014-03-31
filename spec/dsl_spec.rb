require "benchcc/dsl"

require "rspec"


describe Benchcc::DSL do
  it {
    expect(Benchcc::DSL.instance_methods).to eq([:benchmark])
  }
end

# It sucks, but I think RSpec screws up the method lookup because we can't
# put this in an `it { ... }`. If we made a mistake, unit tests will blow
# up, which is good enough.
def use_at_global_scope
  benchmark "test"
end
use_at_global_scope