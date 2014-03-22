require "benchcc/utils"

require "docile"
require "erb"
require "pathname"
require "tempfile"


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

      self.name        @id.to_s.gsub(/_/, ' ').capitalize
      self.description nil
      self.input_file  @benchmark.input_file
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

    # input_file: Pathname
    #
    # Path of a file where the technique is implemented. This defaults to
    # the input file of the parent benchmark. The extension of the file
    # determines whether we treat it as a source file or as an ERB
    # template from which the source should be generated.
    #
    # If the file is a template, the following variables are in scope when we
    # evaluate the template:
    #
    # env: Hash
    #   Contains all the informations.
    #
    # env[:compiler]: Symbol
    #   The id of the compiler used to compile the benchmark.
    #
    # env[:input]: Integer
    #   The size of the input to whatever is being benchmarked.
    #
    # env[technique_id]: true
    def input_file(path = @infile)
      @infile = Pathname.new(path)
    end

    # requires: Proc -> Proc
    #
    # States that a predicate must be satisfied for the technique to be
    # enabled. By default, the technique is always enabled. Calling this
    # method several times will cause the technique to be enabled when all
    # the predicates are satisfied.
    #
    # The method returns the (complete) predicate that must be satisfied
    # for the technique to be enabled.
    def requires(predicate)
      tmp = @enabled.dup
      @enabled = -> (env) { tmp.call(env) and predicate.call(env) }
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

  private
    def template_file?(filename)
      File.fnmatch?("*.erb.*" , File.basename(filename))
    end

    def with(env, &block)
      if disabled? env
        raise "Technique is disabled in the current context."
      end

      if template_file? self.input_file
        code = ERB.new(File.read(self.input_file))
        code.filename = self.input_file
        tmp = Tempfile.new(['', '.cpp'])

        fresh_binding = eval("-> (env) { proc {} }", TOPLEVEL_BINDING)
                                                        .call(env).binding
        tmp.write(code.result(fresh_binding))
        tmp.close # flushes the file

        yield tmp.path
      else
        yield self.input_file
      end
    end

    def measure_anything(xs, cc, &block)
      xs = xs.to_a
      envs = xs.map { |x| {:input => x, @id => true, :compiler => cc.id} }
      xs.zip(envs)
        .select { |x, e| self.enabled? e }
        .map    { |x, e| [x, block.call(e)] }
    end

  public
    # time: [Integers] x Compiler -> [Benchmark.Tms]
    #
    # Time the compilation of this technique using the given compiler.
    #
    # The :input key of the environment is set to each element in xs.
    # Note that for any x in xs, if the environment generated with that
    # x causes the technique to be disabled, then nothing is done.
    def time(xs, compiler)
      measure_anything(xs, compiler) do |env|
          with(env, &compiler.method(:compile)).real
      end
    end
  end # class Technique
end # module Benchcc