require "benchcc/benchmark_suite"
require "benchcc/compiler"
require "benchcc/technique"
require "benchcc/utils"

require "docile"
require "gnuplot"
require "pathname"


module Benchcc
  class Benchmark
    extend Dsl

    # Creates a new benchmark with the given id.
    #
    # If a block is given, it is used to populate the attributes of the
    # benchmark using Docile. If a parent benchmark suite is specified,
    # it is used instead of the default benchmark suite.
    def initialize(id, suite = BenchmarkSuite.new, &block)
      @id = id
      @suite = suite
      @tasks = []
      @techniques = Hash.new
      @compilers = OnFirstShift.new(@suite.compilers.dup, &:clear)

      self.name             @id.to_s.gsub(/_/, ' ').capitalize
      self.description      nil
      self.output_directory @suite.output_directory / @id.to_s
      self.input_file       (@suite.input_directory / @id.to_s).sub_ext(".erb.cpp")
      Docile.dsl_eval(self, &block) if block_given?

      @suite.register(self)
    end

    # id: Symbol
    #
    # Token uniquely identifying the benchmark within a suite.
    attr_reader :id

    # name: String (opt)
    #
    # Optional pretty name of the benchmark. Defaults to a prettified
    # version of id.
    dsl_accessor :name

    # description: String (opt)
    #
    # Optional description of the benchmark. Defaults to nil.
    dsl_accessor :description

    # output_directory: Pathname (opt)
    #
    # Directory where the benchmark results should be stored. Defaults to
    # `suite_output_directory/benchmark_id` if a suite was given on
    # construction, and to `cwd/benchmark_id` otherwise.
    def output_directory(path = @outdir)
      @outdir = Pathname.new(path)
    end

    # input_file: Pathname (opt)
    #
    # File where the benchmark is implemented. Defaults to
    # `suite_input_directory/benchmark_id.erb.cpp` if a suite was given
    # on construction, and to `cwd/benchmark_id.erb.cpp` otherwise.
    def input_file(path = @infile)
      @infile = Pathname.new(path)
    end

    # technique: Symbol(s) (opt)
    #
    # Equivalent to `Technique.new` with the parent benchmark being `self`.
    # If a block is supplied, it is passed to `Technique.new`. If more than
    # one id is given, this is equivalent to calling the method several times
    # with a single id, except that no block may be given.
    def technique(id, *more, &block)
      if !more.empty? && block_given?
        raise "Can't supply a block when multiple ids are provided."
      end

      for t in [id] + more
        raise "Overwriting an existing technique." if @techniques.has_key? t
        @techniques[t] = Technique.new(t, self, &block)
      end
    end

    # compiler: Symbol(s) (opt)
    #
    # Adds a compiler to the set of compilers supported by the benchmark.
    # This defaults to the set of compilers supported by the parent benchmark
    # suite. Adding one or more compilers with this method will cause only
    # those compilers to be supported by this benchmark.
    #
    # If more than one compiler id is given, it is equivalent to calling the
    # method with a single id several times.
    def compiler(id, *more)
      @compilers << Compiler[id]
      more.each(method(:compiler))
    end

    def to_s
      techs = @techniques.values.map(&:to_s).join("\n").indent(4)
      if @file
        "#{self.name} (self.input_file):\n#{techs}\n"
      else
        "#{self.name}:\n#{techs}\n"
      end
    end

    # time: [Integer] -> [Proc]
    #
    # When the benchmark is run, the techniques will all be timed for
    # inputs in the given interval, and with all supported compilers.
    def time(xs)
      task = -> (cc) {
        Gnuplot.open do |gp|
          Gnuplot::Plot.new(gp) do |plot|
            plot.title      "#{self.name} with #{cc.id}"
            plot.xlabel     "Input size"
            plot.ylabel     "Compilation time"
            plot.format     'y "%f s"'

            plot.term       "png"
            plot.output     (self.output_directory / cc.id).sub_ext(".png")
            plot.data = @techniques.values.map { |tech|
              # Note: we must transpose because Gnuplot expects the
              # data as [[x...], [y...]] instead of [[x, y]...].
              curve = tech.time(xs, cc).transpose
              Gnuplot::DataSet.new(curve) { |ds|
                ds.with = "lines"
                ds.title = tech.name
              }
            }
          end
        end
      }
      @tasks << task
    end

    # run: Nil
    #
    # Runs all the recorded tasks.
    def run
      @tasks.product(@compilers).each do |task, cc|
        task.call(cc)
      end
    end
  end # class Benchmark
end # module Benchcc