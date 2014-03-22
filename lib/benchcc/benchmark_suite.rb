require "benchcc/benchmark"
require "benchcc/compiler"
require "benchcc/utils"

require "docile"
require "pathname"


module Benchcc
  class BenchmarkSuite
    # Create a suite of benchmarks.
    #
    # The benchmark suite should be populated in the block using
    # Docile-style attributes.
    def initialize(&block)
      @benchmarks = Hash.new
      @compilers = OnFirstShift.new(Compiler.registered.dup, &:clear)

      self.output_directory Pathname.getwd
      self.input_directory  Pathname.getwd
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

    # input_directory: Pathname (opt)
    #
    # Input directory for the benchmarks. Defaults to the current directory.
    def input_directory(path = @indir)
      @indir = Pathname.new(path)
    end

    # output_directory: Pathname (opt)
    #
    # Output directory for the benchmark results. Defaults to the current
    # directory.
    def output_directory(path = @outdir)
      @outdir = Pathname.new(path)
    end

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
      @compilers << Compiler[id]
      more.each(&method(:compiler))
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
    # run_from_cli: Nil
    #
    # Runs a benchmark suite from the command line. See usage() for details.
    def run_from_cli(argv)
      wrong = argv.keep_if { |bm| not @benchmarks.has_key? bm }
      usage("Unknown benchmarks #{wrong}") unless wrong.empty?
      run(*argv)
    end
  end # class Suite
end # module Benchcc