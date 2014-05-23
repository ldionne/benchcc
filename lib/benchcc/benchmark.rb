require_relative 'compiler'
require 'ruby-progressbar'
require 'tilt'
require 'timeout'


module Benchcc
  class RenderHelper
    def initialize(directory)
      @directory = directory
      @locals = {}
    end

    def render(file, **locals, &block)
      @locals.merge!(locals)
      Tilt::ERBTemplate.new("#{@directory}/#{file}").render(self, **@locals, &block)
    end
  end

  class Benchmark
    def initialize(directory)
      @directory = directory
    end

    def environments
      @envs_ ||= eval(File.read("#{@directory}/_env.rb")).to_a
    end

    def implementations
      @impls_ ||= Dir["#{@directory}/*.erb.cpp"].map { |file|
        File.basename(file, '.erb.cpp')
      }
    end

    def run(implementation, &compile)
      if !implementations.include? implementation
        raise ArgumentError, "unknown implementation #{implementation}"
      end
      renderer = RenderHelper.new(@directory)

      3.times { # rehearse
        code = renderer.render("#{implementation}.erb.cpp", **environments.first)
        begin; compile.call(code); rescue CompilationError; end
      } unless environments.empty?

      begin
        progress = ProgressBar.create(
          format: "#{@directory}/#{implementation} %p%% | %B |",
          total: environments.size)
        consecutive_errors, data = 0, []
        environments.each do |env|
          break if consecutive_errors >= 2
          code = renderer.render("#{implementation}.erb.cpp", **env)
          begin
            Timeout::timeout(10) { data << env.merge(compile.call(code)) }
            consecutive_errors = 0
          rescue CompilationError, Timeout::Error => e
            $stderr << e
            consecutive_errors += 1
          end
          progress.increment
        end
        return data

      ensure
        progress.finish
      end
    end

    def dependencies_of(implementation)
      ["#{@directory}/#{implementation}.erb.cpp", "#{@directory}/_env.rb"]
    end
  end
end