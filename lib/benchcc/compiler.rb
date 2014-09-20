require 'open3'
require 'pathname'
require 'tempfile'


module Benchcc
  class CompilationError < RuntimeError
  end

  # Basic interface to compiler frontends.
  class Compiler
    # Show the name and the version of the compiler.
    def to_s
      raise NotImplementedError
    end

    # compile: Path -> Hash
    #
    # Compile the given file and return compilation statistics.
    #
    # Additional compiler-specific arguments may be specified. A
    # `CompilationError` is raised if the compilation fails for
    # whatever reason.
    def compile(file, *args)
      raise NotImplementedError
    end

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
  end # class Compiler

  class Clang < Compiler
    def initialize(binary)
      @exe = `which #{binary}`.strip
      raise "#{binary} not found" unless $?.success?
    end

    def compile(file, *args)
      file = Pathname.new(file).expand_path
      command = "/usr/bin/time -l #{@exe} #{args.join(' ')} -ftime-report #{file}"
      stdout, stderr, status = Open3.capture3(command)

      if status.success?
        memusg = stderr.match(/(\d+)\s+maximum/)[1].to_i

        section = -> (title) {
          title.gsub!(' ', '\s')
          /(
              ===-+===\n
              .*#{title}.*\n
              ===-+===\n
              (.|\n)+?(?====)
          )|(
              ===-+===\n
              .*#{title}.*\n
              ===-+===\n
              (.|\n)+
          )/x
        }
        time = stderr.match(section["Miscellaneous Ungrouped Timers"]).to_s
                     .match(/(\d+\.?\d+).+?Total/)[1]
        return {
          compilation_time: time,
          memory_usage: memusg
        }

      else
        err_string = <<-EOS
          > #{command}
          #{stderr}

          [compiling:
          #{file.read}
          ]
        EOS
        raise CompilationError.new(err_string)
      end
    end
  end

  class GCC < Compiler
    def initialize(binary)
      @exe = `which #{binary}`.strip
      raise "#{binary} not found" unless $?.success?
    end

    def compile(file, *args)
      file = Pathname.new(file).expand_path
      command = "/usr/bin/time -l #{@exe} #{args.join(' ')} -ftime-report #{file}"
      stdout, stderr, status = Open3.capture3(command)

      if status.success?
        time = stderr.match(/TOTAL.+/).to_s.split[-3].to_f
        memusg = stderr.match(/(\d+)\s+maximum/)[1].to_i
        return {
          compilation_time: time,
          memory_usage: memusg
        }
      else
        err_string = <<-EOS
          > #{command}
          #{stderr}

          [compiling:
          #{file.read}
          ]
        EOS
        raise CompilationError.new(err_string)
      end
    end
  end
end