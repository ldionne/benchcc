require "spec_helper"


describe Benchcc::BenchmarkSuite do

  describe "empty suite" do
    let(:suite) { Benchcc::BenchmarkSuite.new }
    it {
      expect(suite.input_directory).to eq(Dir.getwd)
      expect(suite.output_directory).to eq(Dir.getwd)
      expect(suite.compilers).to eq(Benchcc::Compiler.list)
    }
  end

  describe "specify compiler at suite level" do
    let(:suite) { Benchcc::BenchmarkSuite.new { compiler :clang } }
    it { expect(suite.compilers).to eq([:clang]) }
  end

  describe "run" do
    it "fails if the benchmark is unknown" do
      expect { Benchcc::BenchmarkSuite.new.run(:unknown) }.to raise_error
    end

    it "runs the right benchmark" do
      ran = nil
      suite = Benchcc::BenchmarkSuite.new do
        benchmark(:bm1) { task { ran = :bm1 } }
        benchmark(:bm2) { task { ran = :bm2 } }
      end

      suite.run(:bm1)
      expect(ran).to eq(:bm1)

      suite.run(:bm2)
      expect(ran).to eq(:bm2)
    end
  end

  describe "run from command line" do
    it "runs the right benchmark" do
      ran = nil
      suite = Benchcc::BenchmarkSuite.new do
        benchmark(:bm1) { task { ran = :bm1 } }
        benchmark(:bm2) { task { ran = :bm2 } }
      end

      suite.run_from_cli(%w{some_program bm1})
      expect(ran).to eq(:bm1)

      suite.run_from_cli(%w{some_program bm2})
      expect(ran).to eq(:bm2)
    end
  end

end