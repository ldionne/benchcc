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

  def benchmark(file, envs, timeout: 10,
                            relative_to: File.dirname(file),
                            stderr: $stderr,
                            progressbar_format: "#{file} %p%% | %B |",
                            &block)
    progress = ProgressBar.create(format: progressbar_format, total: envs.size)
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

    def data.to_csv
      return CSV.generate(headers: :first_row) do |csv|
        csv << self.first.keys unless self.empty?
        self.each { |line| csv << line.values }
      end
    end

    return data
  ensure
      progress.finish
  end
  module_function :benchmark
end