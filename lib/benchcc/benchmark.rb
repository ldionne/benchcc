require_relative 'compiler'
require 'csv'
require 'pathname'
require 'ruby-progressbar'
require 'tilt'
require 'timeout'


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

  def benchmark(erb_file, environments, timeout: 10,
                evaluate_erb_relative_to: File.dirname(erb_file), &bench)
    erb_file = Pathname.new(erb_file)
    progress = ProgressBar.create(format: '%p%% | %B |', total: environments.size)

    data = CSV.generate({headers: :first_row}) do |csv|
      csv << [:input_size, :compilation_time, :memory_usage, :run_time]

      environments.each do |env|
        code = Renderer.new(evaluate_erb_relative_to).render(erb_file, **env)
        begin
          Tempfile.create([erb_file.basename, '.cpp']) do |tmp|
            tmp.write(code) && tmp.close
            bench_data = Timeout::timeout(timeout) {
              bench.call(tmp.path, env)
            }
            row = {
              input_size: env[:input_size],
              compilation_time: bench_data[:compilation_time],
              memory_usage: bench_data[:memory_usage],
              run_time: bench_data[:run_time] # TODO: implement this
            }
            csv << row
          end
        rescue CompilationError, Timeout::Error => e
          $stderr << e
          break
        end
        progress.increment
      end
    end
    return data
  ensure
    progress.finish
  end
  module_function :benchmark
end