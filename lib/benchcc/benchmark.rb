require "benchcc/compiler"
require "benchcc/utility"

require "gnuplot"
require "ostruct"
require "rake"
require "ruby-progressbar"
require "set"


module Benchcc
  # Rake task for benchmarking the compilation of a file.
  #
  # A benchmark task takes one optional argument named `:compiler`. It
  # represents the compiler to use for benchmarking, and it defaults
  # to the `:default` compiler.
  class Benchmark < Rake::Task
    # Use the `benchmark` method to create `Benchmark`s, not this.
    def initialize(*args)
      super *args
      @variants = Hash.new
      @predicates = []
    end

    # input_file: String
    #
    # Path of the file where the benchmark is implemented. Defaults to
    # the name of the task.
    def input_file
      @input_file || name
    end

    attr_writer :input_file

    # output_chart: String
    #
    # Path of the file where the plot should be written. Defaults to
    # `input_file`, except with a different extension suitable for the
    # graph content.
    def output_chart
      @output_chart || input_file.chomp(File.extname(input_file)) + ".png"
    end

    attr_writer :output_chart

    # variant: String x Values -> Nil
    #
    # Registers a new variable parameterizing the benchmark.
    #
    # Benchmarks are parameterized with variables that can range over
    # different values. When the benchmark is run, the actions associated
    # with it can access all the possible combinations of those variables.
    # Since some combinations may be nonsensical, a filter may be applied
    # and only the valid combinations are kept (see `requires` for details).
    #
    # If `variant` is called with the name of a variable that already exists,
    # the possible values of the variable are merged with the new ones.
    def variant(name, domain)
      @variants[name] ||= Set.new
      @variants[name].merge(domain)
    end

    # all_variants: Hashes
    #
    # Return all the possible combinations of variables parameterizing
    # the benchmark. The combinations are not filtered.
    def all_variants
      Utility.hash_product(@variants)
    end


  private
    def if_then_require(&condition)
      bm, r = self, Object.new
      r.define_singleton_method(:then_require) do |&predicate|
        bm.requires { |*args|
          condition.call(*args) ? predicate.call(*args) : true
        }
        # `bm.requires` returns `bm`, which would allow method
        # chaining and would make the semantics of `if_` ambiguous.
        return nil
      end
      return r
    end

  public
    # Micro-DSL to register a predicate under certain conditions.
    #
    # if_(key: value, ...) { |env| condition }.then_require { |env| predicate }
    #   Requires the predicate if `value === env[key]` and if the `condition`
    #   is satisfied. If no keys are specified, only the condition is
    #   considered. If no condition is provided, it defaults to true.
    #   However, either keys or a condition must be specified.
    def if_(**variants, &condition)
      if variants.empty? && !block_given?
        raise ArgumentError, "if_ may not be called without arguments"
      end
      return if_then_require(&condition) if variants.empty?

      condition ||= proc { true }
      if_ { |env|
        condition.call(env) &&
        variants.any? { |key, value| value === env[key.to_sym] }
      }
    end

    # requires: Proc -> self
    #
    # Register a predicate to be satisfied for the benchmark to be enabled.
    #
    # By default, the benchmark is always enabled. Calling this method several
    # times will cause the benchmark to be enabled when all the registered
    # predicates are satisfied.
    #
    # Returns self to allow some useful method chains.
    def requires(&predicate)
      @predicates << predicate
      return self
    end

    # enabled?: Hash or OpenStruct -> bool
    #
    # Returns whether the benchmark is enabled in the given context.
    # The context is converted to an `OpenStruct` before it is sent
    # to the predicates of the benchmark. Note that predicates may
    # not modify the context since it is frozen.
    def enabled?(context)
      ctx = OpenStruct.new(context).freeze
      @predicates.all? { |predicate| predicate.call(ctx) }
    end

    # Negates the enabled? method; provided for convenience.
    def disabled?(context)
      !enabled? context
    end

    # plot: Integers -> Nil
    #
    # Plot compilation time statistics.
    #
    # When the benchmark is run, the associated file will be compiled and
    # time statistics will be plotted for all valid variations of the
    # benchmark. Before determining whether the benchmark is enabled for a
    # given variation, these fields are set in the hash of variations:
    # - the `:input` field is set to each value in `inputs`
    # - the `:compiler` field is set to the compiler in use
    #
    # If a block is given, it is called with the plot at the very end
    # so it may customize it.
    def plot(inputs)
      enhance do |_, args|
        inputs = inputs.to_a # Make sure it's not a lazy enumerator.
        cc = Compiler[args.compiler]

        if application.options.trace
          application.trace "** Benchmark #{input_file} with #{cc}"
          progress = ProgressBar.create(
              format: "%t %p%% | %B |",
              total: all_variants.size * inputs.size)
        end

        Gnuplot.open do |io|
          Gnuplot::Plot.new(io) do |pl|
            pl.title  "#{name} with #{cc}"
            pl.xlabel "Input size"
            pl.ylabel "Compilation time"
            pl.format 'y "%f s"'
            pl.term   "png"
            pl.output output_chart

            all_variants.each do |variant|
              # Laziness is important for the progress to be updated correctly.
              data = inputs.lazy
                .map { |x|
                  variant.merge(input: x, compiler: cc)
                         .tap { progress.increment if progress }
                }
                .select(&method(:enabled?))
                .map { |ctx| [ctx[:input], cc.rtime(input_file, ctx).real] }
                .to_a.transpose

              pl.data << Gnuplot::DataSet.new(data) { |ds|
                ds.with = "lines"
                ds.title = variant.values.map(&:to_s).join("_")
              } unless data.empty?
            end

            yield pl if block_given?
          end
        end
      end
    end
  end # class Benchmark

  # Create a benchmark with the given name.
  #
  # If a block is given, the benchmark object is yielded to it so
  # the benchmark attributes can be populated.
  def benchmark(name)
    bm = Benchmark.define_task(name, [:compiler]) do |_, args|
      args.with_defaults(compiler: :default)
    end
    yield bm if block_given?
    return bm
  end
  module_function :benchmark
end # module Benchcc

=begin

module Benchcc
  class Benchmark
    # output_directory: String (opt)
    #
    # Directory where the benchmark results should be stored. Defaults to
    # `suite_output_directory/benchmark_id`.
    dsl_accessor :output_directory
  end # class Benchmark

  class Config
    # requires: Hash x Proc -> Nil
    #
    # Specify conditions that must be met in order for this configuration to
    # be enabled.
    #
    # If `key => value` pairs are passed to the method, the environment must
    # include those pairs for the configuration to be enabled. If a block is
    # given, it is taken as a predicate (to be called on the environment) that
    # must be satisfied for the configuration to be enabled.
    #
    # By default, the configuration is always enabled. Calling this method
    # several times will cause the configuration to be enabled when all the
    # registered conditions are satisfied.
    def requires(**keys, &predicate)
      predicate ||= proc { true }
      @predicates << -> (env) { keys.subsetof?(env) && predicate.call(env) }
    end

    # compiler: Symbol(s) -> Nil
    #
    # Require the compiler to be one of the given `compiler_ids` for this
    # config to be enabled.
    def compiler(*compiler_ids)
      self.requires { |env| compiler_ids.include?(env[:compiler]) }
    end

    # env: Hash x Proc -> Nil
    #
    # Specify modifications to perform on the environment before the
    # configuration is benchmarked.
    #
    # If `key => value` pairs may are passed to the method, they are merged
    # into the environment. If a block is given, it is called with the
    # environment before the config is benchmarked and may return it modified.
    # If the method is called several times, the modifications to perform on
    # the environment are all performed in their registration order.
    def env(**keys, &modifs)
      modifs ||= proc { |env| env }
      @modifs << -> (env) { modifs.call(env.merge(keys)) }
    end

    # with: Hash -> ...
    #
    # Augment the environment with the registered modifications and yield
    # to the block. This method also augments the environment with
    # `:config => self.id`.
    def with(env)
      env = env.merge(config: self.id)
      env = @modifs.reduce(env) { |e, modif| modif.call(e) }
      yield env
    end
  end # class Technique
end # module Benchcc

=end