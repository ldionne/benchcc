require "benchcc/utility"


module Benchcc
  class CompilationError < RuntimeError
    def initialize(command_line, file, env = nil)
      @cli = command_line
      @code = File.read(file)
      @env = env
    end

    attr_accessor :env

    def to_s
      env = "environment was #{@env}" if @env
      <<-EOS
compilation failed when invoking "#{@cli}":
#{env}
#{'-' * 80}
#{@code}
#{'-' * 80}
EOS
    end
  end

  # This class contains the interface of compiler frontends.
  #
  # It also manages the registration of new compiler frontends. To register
  # a new compiler frontend, simply create a new instance of `Compiler`
  # implementing the required methods (they are documented) and you are done.
  #
  # A default compiler frontend is provided; it is taken to have a GCC-like
  # frontend and it uses the `cc` binary. This works at least on OS X 10.9.
  class Compiler
    @@compilers = Hash.new

    # Compiler.list: Compilers
    #
    # Returns an array of the currently registered compilers.
    def self.list
      @@compilers.values
    end

    # Compiler[]: String or Symbol -> Compiler
    #
    # Returns the compiler associated to the given id.
    def self.[](id)
      if !@@compilers.has_key? id.to_sym
        raise ArgumentError, "unknown compiler #{id}"
      end
      @@compilers[id.to_sym]
    end

    # Compiler[]=: String or Symbol x Compiler -> Compiler
    #
    # Register a new compiler with the given id.
    def self.[]=(id, compiler)
      if @@compilers.has_key? id.to_sym
        raise ArgumentError,
              "overwriting existing compiler #{id} with #{compiler}"
      end
      @@compilers[id.to_sym] = compiler
    end

    # initialize: String or Symbol -> Compiler
    #
    # Create and register a new compiler with the given id. If a block is
    # given, `self` is yielded to it so the remaining attributes may be
    # populated.
    def initialize(id)
      @id = id.to_sym
      Compiler[@id] = self
      yield self if block_given?
    end

    # id: Symbol
    #
    # A symbol uniquely identifying a given compiler.
    #
    # In most cases, it should be something carrying the name and the
    # version of the compiler. For example, an identifier for Clang v3.5
    # could be clang35.
    attr_reader :id

    # Maximum template recursion depth supported by the compiler.
    # This must be set explicitly.
    def template_depth
      @template_depth || (raise NotImplementedError)
    end
    attr_writer :template_depth

    # Maximum constexpr recursion depth supported by the compiler.
    # This must be set explicitly.
    def constexpr_depth
      @constexpr_depth || (raise NotImplementedError)
    end
    attr_writer :constexpr_depth

    # cli: Path -> String
    #
    # Return the command line needed to compile the given file.
    # This must be implemented in subclasses.
    def cli(file)
      raise NotImplementedError
    end

    # Show the name and the version of the compiler.
    # This must be implemented in subclasses.
    def to_s
      raise NotImplementedError
    end

    # compile: Path -> Nil
    #
    # Compile the given file.
    #
    # By default, executes the result of `cli(file)`. A `CompilationError`
    # is raised if the compilation fails for whatever reason.
    def compile(file)
      `#{cli(file)}`
      raise CompilationError.new(cli(file), file) unless $?.success?
    end

    # time: Path -> ::Benchmark.Tms
    #
    # Time the compilation of the given file.
    def time(file, **opts)
      stats = Utility.time(**opts) { compile(file) }
      stats.instance_variable_set(:@label, to_s)
      return stats
    end

    # rtime: Path x Hash or OpenStruct -> ::Benchmark.Tms
    #
    # Equivalent to `time`, except the file is taken to be an ERB template
    # that is generated with the given environment before compiling.
    def rtime(file, env, **opts)
      code = Utility.from_erb(file, env)
      hints = [File.basename(file), File.extname(file)]
      begin
        return Tempfile.with(code, hints) { |tmp| time(tmp.path, **opts) }
      rescue CompilationError => e
        e.env = env
        raise e
      end
    end
  end # class Compiler


  # Class for compilers with a GCC-like frontend.
  #
  # This covers at least GCC and Clang.
  class GccFrontend < Compiler
    def initialize(id)
      super id
      @wflags = []
      @includes = []
      yield self if block_given?
    end

    # binary: String
    #
    # Path of the compiler binary on the system.
    # This must be set explicitly.
    attr_accessor :binary

    # wflags: Strings (opt)
    #
    # Array of strings representing warning flags. For example,
    # `gcc.wflags = %w{-Wall -Wextra -pedantic}`.
    attr_accessor :wflags

    # includes: Strings (opt)
    #
    # Array of strings representing include paths. For example,
    # `gcc.includes = %w{~/my/lib/include /usr/local/include}`.
    attr_accessor :includes

    def cli(file)
      incl = includes.map(&"-I ".method(:+)).join(" ")
      warn = wflags.join(" ")
      "#{binary} -o /dev/null -std=c++11 #{warn} #{incl} -c #{file}"
    end

    def to_s
      `#{binary} --version`.lines.first.strip
    end
  end # class GccFrontend

  GccFrontend.new :default do |cc|
    cc.template_depth = 256   # these are complete guesses
    cc.constexpr_depth = 256
    cc.binary = "cc"
  end
end # module Benchcc