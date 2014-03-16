require "benchcc/benchmark"
require "benchcc/utils"

require "docile"


module Benchcc
  class BenchmarkSuite
    # Create a suite of benchmarks.
    #
    # The benchmark suite should be populated in the block using
    # Docile-style attributes.
    def initialize(&block)
      @benchmarks = Hash.new
      Docile.dsl_eval(self, &block) if block_given?
    end

    # benchmark: Symbol -> Benchmark
    #
    # Creates a new benchmark with the given id. The block can be used to
    # populate the benchmark as with Benchmark.new.
    def benchmark(id, &block)
      raise "Overwriting an existing benchmark." if @benchmarks.has_key? id
      @benchmarks[id] = Benchmark.new(id, &block)
    end

    def to_s
      @benchmarks.values.map(&:to_s).join("\n")
    end

    # run: Nil
    #
    # Runs the benchmarks with the specified ids. By default, all the
    # benchmarks are run.
    def run(*benchs)
      benchs = @benchmarks.values.map(&:id) if benchs.empty?
      @benchmarks.values_at(*benchs).each(&:run)
    end

  private
    def usage(s = nil)
      msg = <<-EOS
Usage:
    #{File.basename_we($0)} [options] benchmarks...

        benchmarks  A whitespace separated list of benchmarks to run. The
                    benchmarks are identified using their benchmark id.

        --fair      When available, benchmarks will be more fair. For example,
                    all headers will always be included at the beginning of
                    the benchmark to eliminate any difference in header
                    parsing time.
EOS

        $stderr.puts(s) if s
        $stderr.puts(msg)
        exit(2)
    end

  public

    # run: Nil
    #
    # Runs a benchmark suite from the command line. See usage() for details.
    def run_from_cli(argv)
      wrong = argv.keep_if { |bm| not @benchmarks.has_key? bm }
      usage("Unknown benchmarks #{wrong}") unless wrong.empty?
      run(*argv)
    end
  end # class Suite
end # module Benchcc
