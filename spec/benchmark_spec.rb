require "spec_helper"


describe Benchcc::Benchmark do
  it "allows the id to be a string instead of a symbol" do
    bm = Benchcc::Benchmark.new("benchmark_id")
    expect(bm.id).to eq(:benchmark_id)
  end

  describe "empty benchmark" do
    before(:each) do
      @suite = Benchcc::BenchmarkSuite.new
      @bm = Benchcc::Benchmark.new(:benchmark_id, @suite)
    end

    it "has a pretty name" do
      expect(@bm.name).to eq("Benchmark id")
    end

    it "has no description" do
      expect(@bm.description).to eq(nil)
    end

    it "has the right output directory" do
      expect(@bm.output_directory).to eq("#{@suite.output_directory}/benchmark_id")
    end

    it "has the right input file" do
      expect(@bm.input_file).to eq("#{@suite.input_directory}/benchmark_id.erb.cpp")
    end

    it "supports the same compilers as the benchmark suite" do
      expect(@bm.compilers).to eq(@suite.compilers)
    end
  end

  describe "populated benchmark" do
    it "has the specified name, description, compilers and input file" do
      bm = Benchcc::Benchmark.new(:benchmark_id) do
        compiler    :test_compiler
        name        "test_name"
        description "test_description"
        input_file  "test_input_file"
      end

      expect(bm.compilers).to eq([:test_compiler])
      expect(bm.name).to eq("test_name")
      expect(bm.description).to eq("test_description")
      expect(bm.input_file).to eq("test_input_file")
    end
  end

  describe "run" do
    it "runs all the registered tasks" do
      tasks = []
      Benchcc::Benchmark.new(:bm) {
        task { tasks << 1 }
        task { tasks << 2 }
        task { tasks << 3 }
      }.run

      expect(tasks).to include(1, 2, 3)
    end

    it "forwards the environment to the tasks" do
      ran = false
      Benchcc::Benchmark.new(:bm) {
        task { |env|
          ran = true
          expect(env).to include(:key => :value)
        }
      }.run({:key => :value})
      expect(ran).to be_true
    end
  end

  describe "config" do
    for n in 1..4 do
      ids = (1..n).map { |i| "config##{i}" }

      it "creates several configs with the block when one is provided" do
        configs = 0
        Benchcc::Benchmark.new(:bench) { config(*ids) { configs += 1  } }
        expect(configs).to eq(n)
      end

      it "works without a block too" do
        expect {
          Benchcc::Benchmark.new(:bench) { config(*ids) }
        }.not_to raise_error
      end
    end
  end

  describe "time" do
    it "should not explode" do
      Dir.mktmpdir { |dir|
        bm = Benchcc::Benchmark.new(:test) do
          input_file       "spec/test_files/test.erb.cpp"
          output_directory dir
          time             0..1
          config           :config1, :config2
        end

        expect { bm.run }.not_to raise_error
      }
    end
  end

end