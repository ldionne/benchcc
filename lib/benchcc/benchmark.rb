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
      @modifs = proc { |env| env }
    end

    # input_file: String
    #
    # Path of the file where the benchmark is implemented. Defaults to
    # `scope/of/the/task/name_of_the_task`, where the scope refers to the
    # scope in which the task is defined (see Rake namespaces).
    def input_file
      @input_file || File.join(*name.split(":"))
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
    # and only the valid combinations are kept (see `require_` for details).
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

    # env: Hash x Proc -> Nil
    #
    # Specify modifications to perform on the environment before the
    # benchmark is run.
    #
    # If `key => value` pairs are given, they are merged into the environment.
    # If a block is given, it is called with the environment before any filter
    # is applied to the benchmark variants and it should return the modified
    # environment to use for the benchmark. Either keys or a block must be
    # provided.
    #
    # If this method is called several times, the modifications to perform on
    # the environment are all performed in their registration order.
    def env(**keys, &modifs)
      if keys.empty? && !block_given?
        raise ArgumentError, "env may not be called without arguments"
      end

      modifs ||= proc { |e| e }
      tmp = @modifs.dup
      @modifs = -> (e) { modifs.call(tmp.call(e).merge(keys)) }
    end

  private
    class If
      def initialize(bm, &condition)
        @bm = bm
        @condition = condition
      end

      def require_(**variants, &predicate)
        @bm.require_ { |*args|
          @condition.call(*args) ? predicate.call(*args) : true
        }
        return self
      end

      def env(**keys, &modifs)
        modifs ||= proc { |e| e }
        @bm.env { |e| @condition.call(e) ? modifs.call(e.merge(keys)) : e }
        return self
      end
    end

  public
    # if_(key: value, ...) { |env| condition }.then_require { |env| predicate }
    #
    # Micro-DSL to register a predicate under certain conditions.
    #
    # Requires the predicate if `value === env[key]` for any key/value pair in
    # `variants` and if the `condition` is satisfied. If no keys are specified,
    # only the condition is considered. If no condition is provided, it
    # defaults to true. However, either keys or a condition must be specified.
    def if_(**variants, &condition)
      if variants.empty? && !block_given?
        raise ArgumentError, "if_ may not be called without arguments"
      end
      return If.new(self, &condition) if variants.empty?

      condition ||= proc { true }
      if_ { |env|
        condition.call(env) &&
        variants.any? { |key, value| value === env[key.to_sym] }
      }
    end

    # require_(key: value, ...) { |env| predicate }
    #
    # Specify conditions that must be met in order for the benchmark
    # to be enabled.
    #
    # Enables the benchmark if `value === env[key]` for all keys/values in
    # `variants` and if the predicate is satisfied. If no keys are specified,
    # only the predicate is considered. If no predicate is provided, it
    # defaults to true. However, either keys or a predicate must be provided.
    #
    # By default, the benchmark is always enabled. Calling this method
    # several times will cause the benchmark to be enabled when all the
    # registered predicates are satisfied.
    #
    # Returns self to allow chaining methods.
    def require_(**variants, &predicate)
      if variants.empty? && !block_given?
        raise ArgumentError, "require_ may not be called without arguments"
      end

      predicate ||= proc { true }
      @predicates << -> (env) {
        predicate.call(env) &&
        variants.all? { |key, value| value === env[key.to_sym] }
      }
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

  private
    # Generate datasets for every valid combination of benchmark parameters.
    #
    # An array of `[variant, dataset]` is returned, where `variant` is a valid
    # combination of benchmark parameters and `dataset` is the result of
    # calling the block with an environment consisting of `variant` augmented
    # with the compiler and the input for every input in `inputs`.
    #
    # TODO:
    # Refactor this further. We probably want to get rid of the `cc` argument.
    def gather_datasets(inputs, cc, &ys)
      # Make sure we don't over consume a lazy iterator.
      inputs = inputs.to_a
      if application.options.trace
        application.trace "** Benchmark #{input_file} with #{cc}"
        progress = ProgressBar.create(
            format: "%t %p%% | %B |",
            total: all_variants.size * inputs.size)
      end

      all_variants.map { |variant|
        data = inputs.lazy
          .map { |x| variant.merge(input: x, compiler: cc)
                            .tap { progress.increment if progress } }
          .map(&@modifs)
          .select(&method(:enabled?))
          .map { |ctx| ys.call(ctx) }
        [variant, data]
      }
    end

    # Equivalent to `gather_datasets`, except the datasets are not lazy.
    def gather_datasets!(inputs, cc, &ys)
      gather_datasets(inputs, cc, &ys).map! { |ctx, data| [ctx, data.to_a] }
    end

  public
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
        cc = Compiler[args.compiler]
        # We gather the datasets before opening the Gnuplot process to avoid
        # keeping the process open while we benchmark. I'm not sure whether
        # that really changes something, though.
        datasets = gather_datasets!(inputs, cc) { |ctx|
          [ctx[:input], cc.rtime(input_file, ctx).real]
        }

        Gnuplot.open do |io|
          Gnuplot::Plot.new(io) do |pl|
            pl.title  "#{name} with #{cc}"
            pl.xlabel "Input size"
            pl.ylabel "Compilation time"
            pl.format 'y "%f s"'
            pl.term   "png"
            pl.output output_chart

            datasets.each { |ctx, dataset|
              # We transpose because Gnuplot expects datasets to be of
              # the form `[[x...], [y...]]` instead of `[[x, y]...]`.
              pl.data << Gnuplot::DataSet.new(dataset.transpose) { |ds|
                ds.with = "lines"
                ds.title = ctx.values.map(&:to_s).join("_")
              } unless dataset.empty?
            }

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