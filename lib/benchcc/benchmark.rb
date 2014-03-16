require "benchcc/compiler"
require "benchcc/technique"
require "benchcc/utils"

require "docile"
require "gnuplot"


module Benchcc
  class Benchmark
    extend Dsl

    # Creates a new benchmark with the given id.
    #
    # If a block is given, it is used to populate the other attributes of
    # the benchmark using Docile.
    def initialize(id, &block)
      @id = id
      @name = @id.to_s.gsub(/_/, ' ').capitalize
      @description = nil
      @file = nil
      @tasks = []
      @techniques = Hash.new
      @compilers = OnFirstShift.new(Compiler.registered.dup, &:clear)

      Docile.dsl_eval(self, &block) if block_given?
    end

    # id: Symbol
    #
    # Token uniquely identifying the benchmark within a suite.
    attr_reader :id

    # name: String (opt)
    #
    # Optional pretty name of the benchmark. Defaults to a prettified
    # version of id.
    def name(v=@name)
      @name = v
    end
    # Benchcc.dsl_accessor :name

    # description: String (opt)
    #
    # Optional description of the benchmark. Defaults to nil.
    dsl_accessor :description

    # technique: Symbol -> Technique
    #
    # Adds a technique to the benchmark. If a block is given, it is passed to
    # Technique#initialize. The method returns the created technique.
    #
    # Note that the technique is created with the file of the benchmark, if
    # any. Hence, techniques inherit the enclosing benchmark's file by default.
    def technique(id, &block)
      raise "Overwriting an existing technique." if @techniques[id]
      @techniques[id] = Technique.new(id, @file, &block)
    end

    # file: String (opt)
    #
    # Name of a file where the benchmark is implemented. This is only passed
    # down to the techniques created inside the benchmark.
    dsl_setter :file

    # compiler: Symbol -> [Compiler]
    #
    # Adds a compiler to the set of compilers supported for the benchmark.
    # By default, all registered compilers are supported; adding one or
    # more compilers with this method will cause only those compilers to
    # be supported.
    def compiler(id)
      @compilers << Compiler[id]
    end

    def to_s
      techs = @techniques.values.map(&:to_s).join("\n").indent(4)
      if @file
        "#{@name} (@file):\n#{techs}\n"
      else
        "#{@name}:\n#{techs}\n"
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
            plot.title      "#{@name} with #{cc.id}"
            plot.xlabel     "Input size"
            plot.ylabel     "Compilation time"
            plot.format     'y "%f s"'

            plot.term       "png"
            plot.output     "charts/#{@id}_#{cc.id}.png"
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