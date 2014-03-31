require "benchcc/utility"

require "rspec"


describe Numeric do
  describe :round_up do
    it {
      -150.upto(150) do |n|
        expect(n.round_up).to eq(n)
      end
    }

    it {
      (10..150).step(10) do |tenths|
        tenths.downto(tenths-9) do |n|
          expect(n.round_up(1)).to eq(tenths)
        end
        expect((tenths-10).round_up(1)).to eq(tenths-10)
      end
    }
  end
end