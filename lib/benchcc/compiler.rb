require 'open3'
require 'pathname'
require 'tempfile'


module Benchcc
  class CompilationError < RuntimeError
    def initialize(command_line, code, compiler_error_message)
      @cli = command_line
      @code = code
      @compiler_stderr = compiler_error_message
    end

    def to_s
      <<-EOS
  compilation failed when invoking "#{@cli}"
  compiler error message was:
  #{'-' * 80}
  #{@compiler_stderr}

  full compiled file was:
  #{'-' * 80}
  #{@code}
  EOS
    end
  end

  # Basic interface to compiler frontends.
  class Compiler
    # Maximum template recursion depth supported by the compiler.
    def template_depth
      raise NotImplementedError
    end

    # Maximum constexpr recursion depth supported by the compiler.
    def constexpr_depth
      raise NotImplementedError
    end

    # Show the name and the version of the compiler.
    def to_s
      raise NotImplementedError
    end

    # compile_file: Path -> Hash
    #
    # Compile the given file and return compilation statistics.
    #
    # Additional compiler-specific arguments may be specified.
    #
    # A `CompilationError` is be raised if the compilation fails for
    # whatever reason. Either this method or `compile_code` must be
    # implemented in subclasses.
    def compile_file(file, *args)
      raise ArgumentError, "invalid filename #{file}" unless File.file? file
      code = File.read(file)
      compile_code(code, *args)
    end

    # compile_code: String -> Hash
    #
    # Compile the given string and return compilation statistics.
    #
    # This method has the same behavior as `compile_file`, except the code
    # is given as-is instead of being in a file. Either this method or
    # `compile_file` must be implemented in subclasses.
    def compile_code(code, *args)
      tmp = Tempfile.new(["", '.cpp'])
      tmp.write(code)
      tmp.close
      compile_file(tmp.path, *args)
    ensure
      tmp.unlink
    end
  end # class Compiler

  class Clang < Compiler
    def initialize(binary)
      @exe = `which #{binary}`.strip
      raise "#{binary} not found" unless $?.success?
    end

    def compile_file(file, *args)
      file = Pathname.new(file).expand_path
      command = "time -l #{@exe} #{args.join(' ')} -ftime-report #{file}"
      stdout, stderr, status = Open3.capture3(command)
      raise CompilationError.new(command, file.read, stderr) unless status.success?

      return {
        peak_memusg: stderr.match(/(\d+)\s+maximum/)[1].to_i,
        wall_time: stderr.match(/.+Total/).to_s.split[-3].to_f
      }
    end

    def template_depth;  256; end
    def constexpr_depth; 512; end
  end

  class GCC < Compiler
    def initialize(binary)
      @exe = `which #{binary}`.strip
      raise "#{binary} not found" unless $?.success?
    end

    def compile_file(file, *args)
      file = Pathname.new(file).expand_path
      command = "time -l #{@exe} #{args.join(' ')} -ftime-report #{file}"
      stdout, stderr, status = Open3.capture3(command)
      raise CompilationError.new(command, file.read, stderr) unless status.success?

      return {
        peak_memusg: stderr.match(/(\d+)\s+maximum/)[1].to_i,
        wall_time: stderr.match(/TOTAL.+/).to_s.split[-3].to_f
      }
    end

    def template_depth;  900; end
    def constexpr_depth; 512; end
  end

  class Compiler
    def self.guess_from_binary(binary)
      stdout, stderr, status = Open3.capture3("#{binary} --version")
      case stdout
      when /\(GCC\)/
        return GCC.new(binary)
      when /clang/
        return Clang.new(binary)
      else
        raise ArgumentError("unknown compiler #{binary}")
      end
    end
  end
end