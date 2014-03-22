require "pathname"
require "spec_helper"


describe Benchcc do

  describe "empty suite" do
    let(:suite) { Benchcc::BenchmarkSuite.new }
    it {
      expect(suite.input_directory).to eq(Pathname.getwd)
      expect(suite.output_directory).to eq(Pathname.getwd)
      expect(suite.compilers).to eq(Benchcc::Compiler.registered)
    }
  end

  describe "specify compiler at suite level" do
    let(:suite) { Benchcc::BenchmarkSuite.new { compiler :clang } }
    it { expect(suite.compilers).to eq([Benchcc::Compiler[:clang]]) }
  end

  describe "top level empty benchmark" do
    let(:benchmark) { Benchcc::Benchmark.new(:bm_id) }
    it {
      expect(benchmark.id).to eq(:bm_id)
      expect(benchmark.name).to eq("Bm id")
      expect(benchmark.description).to eq(nil)
    }
  end

  describe "top level benchmark with 1 empty technique" do
    let(:benchmark) {
      Benchcc::Benchmark.new(:bm_id) do
        technique :tech
      end
    }
  end

  describe :technique do
    describe "with a single id and no block" do
      Benchcc::Benchmark.new(:bm_id) do
        technique :tech
      end
    end

    describe "with a single id and a block" do
      Benchcc::Benchmark.new(:bm_id) do
        technique :tech do
          name "tech_name"
        end
      end
    end

    describe "with several ids" do
      Benchcc::Benchmark.new(:bm_id) do
        technique :tech1, :tech2, :tech3
      end
    end
  end

end