module Benchcc
  class FailedCompilation < RuntimeError

  end

  class Compiler
    @@compilers = Hash.new

    # Compiler[]: Symbol -> Compiler
    #
    # Returns the Compiler object associated to the given compiler id.
    def self.[](compiler_id)
      if !@@compilers.has_key? compiler_id
        raise ArgumentError, "Unknown compiler #{compiler_id}."
      end
      @@compilers[compiler_id]
    end

    # Compiler.available?: Symbol -> Bool
    #
    # Returns whether the compiler with the given id is available.
    def self.available?(compiler_id)
      @@compilers.has_key? compiler_id
    end

    # Compiler.register: Compiler -> Nil
    #
    # Adds a compiler to the list of available compilers.
    def self.register(compiler)
      if @@compilers.has_key? compiler.id
        raise ArgumentError, "Overwriting existing compiler #{compiler.id}."
      end
      @@compilers[compiler.id] = compiler
    end

    # Compiler.list: [Symbol]
    #
    # Returns the list of available compilers.
    def self.list
      @@compilers.keys
    end


    # id: Symbol
    #
    # A unique id representing the compiler.
    attr_reader :id

    # Creates a new Compiler with the given id.
    #
    # The block is mandatory and calling it with a filename should compile
    # that file.
    def initialize(id, &compile)
      @id = id
      @compile = compile
      Compiler.register(self)
    end

    # Compile the given file.
    def compile(file)
      @compile.call(file)
      raise FailedCompilation.new unless $?.success?
    end
  end # class Compiler

  Compiler.new(:clang) { |file|
    `clang++-3.5 -S #{file} -o /dev/null -I ~/code/mpl11/include -std=c++11`
  }

  Compiler.new(:gcc) { |file|
    `g++-4.9 -S #{file} -o /dev/null -I ~/code/mpl11/include -std=c++11`
  }

  # Compiler.new(:clang) do |cc|
  #   cc.cmd      = "clang++-3.5 -std=c++11"
  #   cc.include_ = proc { |path| "-I #{path}" }
  #   cc.output   = proc { |file| "-o #{file}" }
  #   cc.input    = proc { |file| "-S #{file}" }
  # end

  # Compiler.new(:gcc) do |cc|
  #   cc.cmd      = "g++-4.9 -std=c++11"
  #   cc.include_ = proc { |path| "-I #{path}" }
  #   cc.output   = proc { |file| "-o #{file}" }
  #   cc.input    = proc { |file| "-S #{file}" }
  # end
end # module Benchcc