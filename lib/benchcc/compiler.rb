require "benchcc/utility"


module Benchcc
  class CompilationError < RuntimeError
    def initialize(compiler, file)
      @cli = compiler.cli(file)
      @code = File.read(file)
    end

    def to_s
      <<-EOS
compilation failed when invoking "#{@cli}":
#{'-' * 80}
#{@code}
#{'-' * 80}
EOS
    end
  end

  class Compiler
    # Create a new compiler whose binary is located at `bin`.
    def initialize(bin)
      @cc = bin
      yield self if block_given?
    end

    # Maximum template recursion depth supported by the compiler.
    attr_accessor :template_depth

    # Maximum constexpr recursion depth supported by the compiler.
    attr_accessor :constexpr_depth

    # compile: Path x Paths -> Nil
    #
    # Compile the specified file.
    #
    # If include paths are given, they are added to the header search paths
    # of the compiler.
    def compile(filename, *includes)
      `#{cli(filename, *includes)}`
      raise CompilationError.new(self, filename) unless $?.success?
    end

    # cli: Path x Paths -> String
    #
    # Return the command line that would be executed to compile the
    # given file with the given include paths.
    def cli(filename, *includes)
      includes = includes.map(&"-I ".method(:+)).join(" ")
      warnings = ["-Wall", "-Wextra", "-pedantic"].join(" ")
      "#{@cc} -o /dev/null -std=c++11 #{warnings} #{includes} #{filename}"
    end

    # rtime: Path x Hash or OpenStruct -> ::Benchmark.Tms
    #
    # Equivalent to `time`, except the file is taken to be an ERB template
    # to be generated before compiling.
    def rtime(file, env)
      code = Utility.from_erb(file, env)
      hints = [File.basename(file), File.extname(file)]
      return Tempfile.with(code, hints) { |tmp| time(tmp.path) }
    end

    # time: ... -> ::Benchmark.Tms
    #
    # Time the `compile` method with the given arguments.
    def time(*args)
      stats = Utility.time { compile(*args) }
      stats.instance_variable_set(:@label, to_s)
      return stats
    end

    # Show the name and the version of the compiler.
    def to_s
      `#{@cc} --version`.lines.first.strip
    end
  end # class Compiler

  GCC = Compiler.new("g++-4.9") do |cc|
    cc.template_depth = 900
    cc.constexpr_depth = 512
  end

  CLANG = Compiler.new("clang++-3.5") do |cc|
    cc.template_depth = 256
    cc.constexpr_depth = 512
  end
end # module Benchcc