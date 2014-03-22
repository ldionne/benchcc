require "benchcc/benchmark_suite"
require "benchcc/technique"
require "benchcc/utils"

require "docile"
require "gnuplot"


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
      self.output_directory File.join(@suite.output_directory, @id.to_s)
      self.input_file       File.join(@suite.input_directory, @id.to_s) + ".erb.cpp"
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

    # output_directory: String (opt)
    #
    # Directory where the benchmark results should be stored. Defaults to
    # `suite_output_directory/benchmark_id`.
    dsl_accessor :output_directory

    # input_file: String
    #
    # Path of a file where the benchmark is implemented. This defaults to
    # `suite_input_directory/benchmark_id.erb.cpp`. The extension of the file
    # determines whether we treat it as a source file or as an ERB template
    # from which the source should be generated. If the file is a template,
    # the environment is available as `env` when evaluating the template.
    dsl_accessor :input_file

    # technique: Symbol(s) (opt)
    #
    # Equivalent to `Technique.new` with the parent benchmark being `self`.
    # If a block is supplied, it is passed to `Technique.new`. If more than
    # one id is given, this is equivalent to calling the method several times
    # with a single id and the same block.
    def technique(*ids, &block)
      raise ArgumentError, "At least one id must be given." if ids.empty?
      ids.each do |id|
        raise "Overwriting an existing technique." if @techniques.has_key? id
        @techniques[id] = Technique.new(id, self, &block)
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
      @compilers << id
      more.each(&method(:compiler))
    end

    # compilers: [Symbol]
    #
    # An array of the compilers supported by the benchmark.
    attr_reader :compilers

    def to_s
      techs = @techniques.values.map(&:to_s).join("\n").indent(4)
      "#{self.name} (self.input_file):\n#{techs}\n"
    end

    # task: Proc -> Nil
    #
    # Registers a task to do when the benchmark is run. Tasks are simply
    # `Procs` called with an environment when the benchmark is run.
    def task(&block)
      raise ArgumentError, "A block must be provided." unless block_given?
      @tasks << block
    end

    # time: [Integer] -> Nil
    #
    # When the benchmark is run, the techniques will all be timed for
    # inputs in the given interval, and with all supported compilers.
    def time(xs)
      task do |env|
        # Just make sure the directories are created.
        FileUtils.makedirs(self.output_directory)

        Gnuplot.open do |gp|
          Gnuplot::Plot.new(gp) do |plot|
            plot.title      "#{self.name} with #{env[:compiler]}"
            plot.xlabel     "Input size"
            plot.ylabel     "Compilation time"
            plot.format     'y "%f s"'

            plot.term       "png"
            plot.output     File.join(self.output_directory, env[:compiler].to_s) + ".png"
            plot.data = @techniques.values.map { |technique|
              # Note: we must transpose because Gnuplot expects the
              # data as [[x...], [y...]] instead of [[x, y]...].
              curve = technique.time(xs, env).transpose
              Gnuplot::DataSet.new(curve) { |ds|
                ds.with = "lines"
                ds.title = technique.name
              }
            }
          end
        end
      end
    end

    # run: Hash -> Nil
    #
    # Runs all the tasks registered in the benchmark, for each supported
    # compiler. If provided, the environment is passed to each task,
    # augmented with the id of the compiler being used: `{:compiler => id}`.
    def run(env = Hash.new)
      @tasks.product(self.compilers).each do |task, cc|
        task.call(env.merge({:compiler => cc}))
      end
    end
  end # class Benchmark
end # module Benchcc