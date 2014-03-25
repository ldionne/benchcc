require "benchcc/benchmark"
require "benchcc/compiler"
require "benchcc/utils"

require "docile"
require "trollop"


module Benchcc
  class BenchmarkSuite
    extend Dsl

    # Create a suite of benchmarks.
    #
    # The benchmark suite should be populated in the block using
    # Docile-style attributes.
    def initialize(&block)
      @benchmarks = Hash.new
      @compilers = OnFirstShift.new(Compiler.list.dup, &:clear)

      self.output_directory Dir.getwd
      self.input_directory  Dir.getwd
      Docile.dsl_eval(self, &block) if block_given?
    end

    # register: Benchmark -> Nil
    #
    # Registers a benchmark in the benchmark suite.
    def register(bm)
      if @benchmarks.has_key? bm.id
        raise ArgumentError, "Overwriting an existing benchmark"
      end
      @benchmarks[bm.id] = bm
    end

    # benchmark: Symbol -> Benchmark
    #
    # Equivalent to `Benchmark.new` with the parent suite being `self`.
    def benchmark(id, &block)
      Benchmark.new(id, self, &block)
    end

    # input_directory: String (opt)
    #
    # Input directory for the benchmarks. Defaults to the current directory.
    dsl_accessor :input_directory

    # output_directory: String (opt)
    #
    # Output directory for the benchmark results. Defaults to the current
    # directory.
    dsl_accessor :output_directory

    # compiler: Symbol(s) (opt)
    #
    # Adds a compiler to the set of compilers supported by the benchmark
    # suite. This defaults to all the supported compilers. If one or more
    # compilers are added with this method, only those compilers will be
    # supported by the benchmark suite.
    #
    # If more than one compiler id is given, it is equivalent to calling the
    # method with a single id several times.
    def compiler(id, *more)
      @compilers << id
      @compilers = @compilers + more
    end

    # compilers: [Compiler]
    #
    # An array of the compilers supported by the benchmark suite.
    attr_reader :compilers

    def to_s
      @benchmarks.values.map(&:to_s).join("\n")
    end

    # run: Nil
    #
    # Runs the benchmark with the specified id. If provided, the environment
    # is passed down to the benchmark.
    def run(bm, env = Hash.new)
      if !@benchmarks.has_key? bm
        raise ArgumentError, "Unknown benchmark <#{bm}>"
      end
      @benchmarks[bm].run(env)
    end

    # run_from_cli: Nil
    #
    # Runs a benchmark suite from the command line.
    def run_from_cli(argv)
      opts = Trollop::options(argv) do
        banner <<-EOS
Usage:
  #{File.basename_we($0)} [options] <benchmark>

where <benchmark> is the id of a benchmark to run and [options] are:
EOS
        opt :fair, "When available, benchmarks will be more fair. For "\
                   "example, all headers will always be included at "  \
                   "the beginning of the benchmark to eliminate any "  \
                   "difference in header parsing time.", :default => false
        opt :list, "List all the available benchmarks", :default => false
      end

      if opts[:list]
        puts @benchmarks.keys
        exit(0)
      end

      bm = argv.last
      unless bm && @benchmarks.has_key?(bm.to_sym)
        Trollop::die "\"#{argv.last}\" does not correspond to a valid benchmark id"
      end
      run(bm.to_sym, {:fair => opts[:fair]})
    end
  end # class Suite
end # module Benchcc