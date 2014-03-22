require "benchcc/compiler"
require "benchcc/utils"

require "docile"


module Benchcc
  class Technique
    extend Dsl

    # Creates a new technique with the given id in the specified benchmark.
    #
    # If a block is given, it is used to populate the attributes of the
    # technique using Docile.
    def initialize(id, benchmark, &block)
      @id = id
      @benchmark = benchmark
      @enabled = proc { true }
      @modify_env = proc { |e| e }

      self.name        @id.to_s.gsub(/_/, ' ').capitalize
      self.description nil
      Docile.dsl_eval(self, &block) if block_given?
    end

    # id: Symbol
    #
    # Token uniquely identifying the technique within a benchmark.
    # This must only contain characters that can appear in a path, since
    # the id might be used to create filenames.
    attr_reader :id

    # name: String (opt)
    #
    # A pretty name for the technique. Defaults to the prettified
    # version of id.
    dsl_accessor :name

    # description: String (opt)
    #
    # Optional description of the technique; defaults to nil.
    dsl_accessor :description

    # requires: Proc -> Proc
    #
    # States that a predicate must be satisfied for the technique to be
    # enabled. By default, the technique is always enabled. Calling this
    # method several times will cause the technique to be enabled when all
    # the predicates are satisfied.
    #
    # The method returns the (complete) predicate that must be satisfied
    # for the technique to be enabled.
    def requires(&predicate)
      raise ArgumentError, "No block given." unless block_given?
      tmp = @enabled.dup
      @enabled = -> (env) { tmp.call(env) and predicate.call(env) }
    end

    # env: Proc -> Nil
    #
    # Register a set of modifications to be performed on the environment
    # before the technique is benchmarked. A block must be given; it will
    # be called with the environment before the technique is benchmarked and
    # it should return the environment to use for the benchmark. Many sets
    # of modifications can be registered by calling this method several times.
    # In this case, the modifications will be performed on the environment
    # in their order of registration.
    def env(&block)
      raise ArgumentError, "A block must be given." unless block_given?
      tmp = @modify_env.dup
      @modify_env = -> (e) { block.call(tmp.call(e)) }
    end

    # enabled?: Hash -> bool
    #
    # Returns whether the technique is enabled in the specified environment.
    def enabled?(env); @enabled.call(env); end

    # disabled?: Hash -> bool
    #
    # Negates the enabled? method; provided for convenience.
    def disabled?(env); !enabled? env; end

    def to_s
      if self.description then "#{self.name}: #{self.description}"
                          else self.name
      end
    end

    # time: [Integers] x Hash -> [Integer x Benchmark.Tms]
    #
    # Time the compilation of this technique with the given environment.
    #
    # The `xs` argument represents the range of inputs to time the compilation
    # with. Note that the technique is only compiled when it is enabled. This
    # method sets `env[:input]` to the current input size for each input size
    # in `xs`, and `env[technique_id]` to true.
    def time(xs, env)
      results = []
      env = env.merge({@id => true})
      for x in xs
        e = @modify_env.call(env.merge({:input => x}))
        if self.enabled? e
          y = Benchcc.configure(@benchmark.input_file, e) do |file|
            Benchcc.time { Compiler[env[:compiler]].compile(file) }.real
          end
          results << [x, y]
        end
      end
      return results
    end
  end # class Technique
end # module Benchcc