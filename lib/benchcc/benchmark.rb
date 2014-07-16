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

  def benchmark(file, envs, timeout: 10, relative_to: File.dirname(file), stderr: $stderr, &block)
    progress = ProgressBar.create(format: "#{file} %p%% | %B |",
                                  total: envs.size)
    data = []
    envs.each do |env|
      code = Renderer.new(relative_to).render(file, **env)
      begin
        Timeout::timeout(timeout) { data << env.merge(block.call(code).to_h) }
      rescue CompilationError, Timeout::Error => e
        stderr << e
        break
      end
      progress.increment
    end
    return data
  ensure
      progress.finish
  end
  module_function :benchmark

  def benchmark_to_csv(file, envs, timeout: 10, relative_to: File.dirname(file), &block)
    data = benchmark(file, envs, timeout: timeout, relative_to: relative_to, &block)
    return CSV.generate(headers: :first_row) do |csv|
      csv << data.first.keys unless data.empty?
      data.each { |line| csv << line.values }
    end
  end
  module_function :benchmark_to_csv
end