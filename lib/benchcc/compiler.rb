require "benchcc/utils"

require "benchmark"


module Benchcc
  class FailedCompilation < RuntimeError

  end

  class Compiler
    @@ccs = Hash.new

    private_class_method :register

    # Compiler.register: Compiler -> Compiler
    #
    # Registers a compiler; this is done automatically when
    # a compiler is created.
    def self.register(compiler)
      if self.registered? compiler.id
        raise "Overwriting existing compiler #{compiler.id}."
      end
      @@ccs[compiler.id] = compiler
    end

    # Compiler.registered: [Compiler]
    #
    # Returns an array containing all the compilers that
    # were created up to now.
    def self.registered
      @@ccs.values
    end

    # Compiler.registered?: Symbol -> Bool
    #
    # Returns whether a compiler id represents a registered compiler.
    def self.registered?(compiler_id)
      @@ccs.has_key? compiler_id
    end

    # Compiler[]: Symbol -> Compiler
    #
    # Returns the Compiler object associated to the given compiler id.
    def self.[](compiler_id)
      if !self.registered? compiler_id
        raise "Unknown compiler #{compiler_id}."
      end
      @@ccs[compiler_id]
    end



    # id: Symbol
    #
    # A unique id representing a compiler.
    attr_reader :id

    # Creates a new compiler with the given id.
    #
    # The (mandatory) block will be called with the name of a file to compile.
    def initialize(id, &command)
      raise "A command must be given." unless block_given?

      @id = id
      @cc = -> (filename) {
        command.call(filename)
        raise FailedCompilation.new unless $?.success?
      }

      Compiler.register(self)
    end

    # compile: String -> Benchmark.Tms
    #
    # Measure the time taken to compile a file.
    #
    # First, the file is compiled a number of times (default 1) as a
    # rehearsal. Then, the file is compiled again a number of times
    # (default 3), during which the compilation time is recorded. The
    # average of these last compilations is returned.
    def compile(filename, repetitions: 3, rehearsals: 1)
      rehearsals.times { @cc.call(filename) }

      avg = repetitions.times
                       .collect { ::Benchmark.measure { @cc.call(filename) } }
                       .average
      avg.instance_variable_set(:@label, @id)
      avg
    end
  end # class Compiler

  Compiler.new(:clang) do |filename|
    `clang++-3.5 -std=c++11 -o /dev/null -I ~/code/mpl11/include -c #{filename}`
  end

  Compiler.new(:gcc) do |filename|
    `g++-4.9 -std=c++11 -o /dev/null -I ~/code/mpl11/include -c #{filename}`
  end
end # module Benchcc