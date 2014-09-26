require_relative 'ext/string'

require 'open3'
require 'pathname'
require 'tempfile'
require 'timeout'


module Benchcc
  class CompilationError < RuntimeError
  end

  class ExecutionError < RuntimeError
  end

  class Clang
    def call(input_file:, features:, compiler_executable:, compiler_options:,
             compilation_timeout:, execution_timeout:)
      stats = {}
      input_file = Pathname.new(input_file)
      Dir.mktmpdir do |tmp_dir|
        if features.include?(:compilation_time)
          compiler_options << '-ftime-report'
        end

        if features.include?(:execution_time)
          compiler_options << "-o#{tmp_dir}/a.out"
        end

        if features.include?(:memory_usage)
          compiler_executable = "/usr/bin/time -l #{compiler_executable}"
        end

        command = "#{compiler_executable} #{compiler_options.join(' ')} #{input_file}"
        stdout, stderr, status = Timeout::timeout(compilation_timeout) {
          Open3.capture3(command)
        }

        if not status.success?
          raise CompilationError.new(<<-EOS.strip_heredoc
            > #{command}
            #{stderr}

            [compiling:
            #{input_file.read}
            ]
          EOS
          )
        end

        if features.include?(:compilation_time)
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
          stats.merge!({compilation_time: time})
        end

        if features.include?(:memory_usage)
          memusg = stderr.match(/(\d+)\s+maximum/)[1]
          stats.merge!({memory_usage: memusg})
        end

        if features.include?(:execution_time)
          command = "/usr/bin/time #{tmp_dir}/a.out"
          stdout, stderr, status = Timeout::timeout(execution_timeout) {
            Open3.capture3(command)
          }
          if status.success?
            time = stderr.match(/(\d+\.?\d*)\s+real/)[1]
            stats.merge!({execution_time: time})
          else
            raise ExecutionError.new(<<-EOS.strip_heredoc
              > #{command}
              #{stderr}

              [running:
              #{input_file.read}
              ]
            EOS
            )
          end
        end

        return stats
      end
    end
  end

  def which(compiler_id)
    case compiler_id
    when 'Clang'
      return Clang.new
    else
      raise ArgumentError.new("Unsupported compiler id: #{compiler_id}")
    end
  end
  module_function :which
end