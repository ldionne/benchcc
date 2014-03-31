require "benchcc/benchmark"

require "rake"
require "rspec"


def testfile(name)
  File.join(File.dirname(__FILE__), "test", name)
end

describe Benchcc::Benchmark do
  before(:each) do
    Rake::Task.clear
  end

  describe "input_file" do
    context "is set explicitly" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.input_file = "filename"
        end
      }

      it "returns the specified filename" do
        expect(@bm.input_file).to eq("filename")
      end
    end

    context "it is not set explicitly" do
      before { @bm = Benchcc.benchmark "test" }

      it "defaults to the name of the task" do
        expect(@bm.input_file).to eq(@bm.name)
      end
    end
  end

  describe "output_chart" do
    context "is set explicitly" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.output_chart = "chartfile"
        end
      }

      it "returns the specified filename" do
        expect(@bm.output_chart).to eq("chartfile")
      end
    end

    context "it is not set explicitly" do
      before { @bm = Benchcc.benchmark "test" }

      it "defaults to the input_file with a png extension" do
        expect(@bm.output_chart).to eq("test.png")
      end
    end
  end

  describe "requires" do
    context "no predicate are registered" do
      before { @bm = Benchcc.benchmark "test" }

      it "is always enabled" do
        expect(@bm.enabled? Hash.new).to be_true
      end
    end

    context "predicates are registered" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.requires { |env| env.param1 }
          bm.requires { |env| env.param2 }
        end
      }

      it "is only enabled when all predicates are satisfied" do
        expect(@bm.enabled? Hash.new).to be_false
        expect(@bm.enabled?({param1: true})).to be_false
        expect(@bm.enabled?({param2: true})).to be_false
        expect(@bm.enabled?({param1: true, param2: true})).to be_true
      end
    end
  end

  describe "if_" do
    before {
      @bm = Benchcc.benchmark "test" do |bm|
        bm.if_ { |env| env.param1 }.then_require { |env| env.param2 }
      end
    }

    it "considers the predicate only when the condition is satisfied" do
      expect(@bm.enabled? Hash.new).to be_true
      expect(@bm.enabled?({param2: false})).to be_true
      expect(@bm.enabled?({param1: true, param2: true})).to be_true
      expect(@bm.enabled?({param1: true, param2: false})).to be_false
    end
  end

  describe "variants" do
    context "no variants were registered" do
      before { @bm = Benchcc.benchmark "test" }

      it "has no variants" do
        expect(@bm.all_variants.empty?).to be_true
      end
    end

    context "variants were registered" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.variant :param1, [:a, :b]
          bm.variant :param2, [:c, :d]
        end
      }

      it "generates all combinations" do
        expect(@bm.all_variants).to include(
          {param1: :a, param2: :c},
          {param1: :a, param2: :d},
          {param1: :b, param2: :c},
          {param1: :b, param2: :d}
        )
      end
    end
  end

  describe "plot" do
    before {
      @bm = Benchcc.benchmark testfile("valid.cpp") do |bm|
        bm.variant :variant1, [:value1, :value2]
        bm.plot 0.upto 1
      end
    }

    context "with specified compiler" do
      it "creates a pretty graph" do
        args = Rake::TaskArguments.new([:compiler], [Benchcc::GCC])
        expect { @bm.execute(args) }.not_to raise_error
        expect(File.file? testfile("valid.png")).to be_true
      end
    end

    context "with default compiler" do
      it "creates a pretty graph" do
        expect { @bm.execute }.not_to raise_error
        expect(File.file? testfile("valid.png")).to be_true
      end
    end

    after {
      File.delete(testfile("valid.png")) if File.exists? testfile("valid.png")
    }
  end
end



=begin
describe Benchcc::Config do

  describe "requires" do
    it "enables the config only when all pairs are in the environment" do
      config = Benchcc::Config.new(:config_id) do
        requires key1: 1, key2: 2
        requires key3: 3
      end

      expect(config.enabled?({key1:1, key2:2, key3:3})).to be_true
      expect(config.enabled?({key1:1, key2:2})).to be_false
      expect(config.enabled?({key1:1, key3:3})).to be_false
      expect(config.enabled?(Hash.new)).to be_false
    end
  end

  describe "env" do
    it "augments the environment with the given pairs" do
      config = Benchcc::Config.new(:config_id) do
        env a: :a
        env b: :b, c: :c
      end

      config.with(Hash.new) do |env|
        expect(env[:a]).to eq(:a)
        expect(env[:b]).to eq(:b)
        expect(env[:c]).to eq(:c)
      end
    end

    it "augments the environment by calling the blocks" do
      config = Benchcc::Config.new(:config_id) do
        env { |e| e.merge({a: :a}) }
        env { |e| e.merge({b: :b}) }
      end

      config.with(Hash.new) do |env|
        expect(env[:a]).to eq(:a)
        expect(env[:b]).to eq(:b)
      end
    end
  end

  describe "compiler" do
    it "enables the config when the right compiler is given" do
      config = Benchcc::Config.new(:config_id) do
        compiler :test_compiler
      end
      expect(config.enabled?({:compiler => :test_compiler})).to be_true
    end

    it "disables the config when the wrong compiler is given" do
      config = Benchcc::Config.new(:config_id) do
        compiler :test_compiler
      end
      expect(config.enabled?({:compiler => :nope})).to be_false
    end

    it "disables the config when no compiler is given" do
      config = Benchcc::Config.new(:config_id) do
        compiler :test_compiler
      end
      expect(config.enabled?(Hash.new)).to be_false
    end
  end
end

=end