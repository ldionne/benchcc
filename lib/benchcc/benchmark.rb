require_relative 'compiler'

require 'csv'
require 'pathname'
require 'ruby-progressbar'
require 'tilt'


module Benchcc
  class Renderer
    def initialize(relative_to)
      @relative_to = Pathname.new(relative_to)
      @locals = {}
    end

    def render(file, **locals, &block)
      @locals.merge!(locals)
      file = Pathname.new(file).expand_path(@relative_to)
      Tilt::ERBTemplate.new(file).render(self, **@locals, &block)
    end
  end

  def benchmark(
      erb_file:, # String or Pathname
      environments:, # Array of Hash
      compilation_timeout:, # Int
      execution_timeout:, # Int
      evaluate_erb_relative_to:, # String or Pathname
      features:, # Array of Symbol
      compiler_executable:, # String
      compiler_id:, # String
      compiler_options: # Array of String
    )
    erb_file = Pathname.new(erb_file)
    progress = ProgressBar.create(format: '%p%% | %B |', total: environments.size)
    compiler = Benchcc::which(compiler_id)

    data = CSV.generate({headers: :first_row}) do |csv|
      csv << [:input_size] + features

      environments.each do |env|
        code = Renderer.new(evaluate_erb_relative_to).render(erb_file, **env)
        begin
          row = {input_size: env[:input_size]}
          Tempfile.create([erb_file.basename, '.cpp']) do |tmp|
            tmp.write(code) && tmp.close

            row.merge!(
              compiler.call(
                input_file: tmp.path,
                features: features,
                compiler_executable: compiler_executable,
                compiler_options: compiler_options,
                compilation_timeout: compilation_timeout,
                execution_timeout: execution_timeout
              )
            )
          end

        rescue CompilationError, CompilationTimeout => e
          $stderr << e
          break

        rescue ExecutionError, ExecutionTimeout => e
          $stderr << e
          break unless features.include?(:compilation_time) || features.include?(:memory_usage)

        ensure
          csv << row
          progress.increment
        end
      end
    end
    return data
  ensure
    progress.finish
  end
  module_function :benchmark
end