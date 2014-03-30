require "benchcc/compiler"
require "benchcc/utility"

require "gnuplot"
require "ostruct"
require "rake"
require "set"


module Benchcc
  class AmbiguousFilename < StandardError
    def initialize(pattern, matches)
      @pattern = pattern
      @matches = matches
    end

    def to_s
      "filename cannot be determined unambiguously "\
                                      "(\"#{@pattern}\" matched #{@matches})"
    end
  end

  class Benchmark < Rake::Task
    def initialize(*args)
      super *args
      @variants = Hash.new
      @predicates = []
    end

    # file: String
    #
    # Path of the file where the benchmark is implemented.
    #
    # By default, the file is `name.*`, where `name` is the name of the
    # benchmark. If that glob pattern matches more than one file, then it
    # is ambiguous and `file` must be specified explicitly.
    def file
      unless @file
        matches = Dir["#{name}.*"]
        raise AmbiguousFilename.new("#{name}.*", matches) if matches.size > 1
        @file = matches.first
        raise "\"#{@file}\" is not a valid file" unless File.file? @file
      end
      return @file
    end

    attr_writer :file

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

    # Micro-DSL to register a predicate under certain conditions.
    #
    # Specifically, `if_ { condition } .then_require { predicate }`
    # is equivalent to registering a predicate that is true whenever
    # `condition` is not satisfied, and that forwards to `predicate`
    # otherwise.
    def if_(&condition)
      bm, r = self, Object.new
      r.define_singleton_method(:then_require) do |&predicate|
        bm.requires { |*args, **kw|
          condition.call(*args, **kw) ? predicate.call(*args, **kw) : true
        }
        return nil # `bm.requires` returns `bm`, which would allow method
                   # chaining and would make the semantics of `if_` ambiguous.
      end
      return r
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
        cc = args.compiler
        if application.options.trace
          application.trace "** Benchmark #{file} with #{cc}"
        end
        Gnuplot.open do |io|
          Gnuplot::Plot.new(io) do |pl|
            pl.title  "#{name} with #{cc}"
            pl.xlabel "Input size"
            pl.ylabel "Compilation time"
            pl.format 'y "%f s"'
            pl.term   "png"
            pl.output name + ".png"

            all_variants.each do |variant|
              data = inputs
                .map { |x| variant.merge(input: x, compiler: cc) }
                .select(&method(:enabled?))
                .map { |ctx| [ctx[:input], cc.rtime(file, ctx).real] }
                .transpose

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

  def benchmark(name)
    bm = Benchmark.define_task(name, [:compiler]) do |_, args|
      args.with_defaults(compiler: CLANG)
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