require 'benchcc/benchmark'
require 'benchcc/compiler'

require 'rspec'
require 'tempfile'


describe Benchcc.method(:benchmark) do
  it('should not throw') {
    envs = [{input_size: 1}, {input_size: 2}]
    Tempfile.create('') do |file|
      expect {
        data = Benchcc.benchmark(file.path, envs) do |file, env|
          {
            compilation_time: 'foo',
            memory_usage: 'bar',
            run_time: 'baz'
          }
        end
      }.not_to raise_error
    end
  }

  it('should stop on timeout') {
    envs = [{input_size: 1}, {input_size: 2}]
    Tempfile.create('') do |file|
      expect {
        data = Benchcc.benchmark(file.path, envs, timeout: 0.1) do |file, env|
          sleep(0.2)
        end
      }.not_to raise_error
    end
  }

  it('should stop on CompilationError') {
    envs = [{input_size: 1}, {input_size: 2}]
    Tempfile.create('') do |file|
      expect {
        data = Benchcc.benchmark(file.path, envs, timeout: 0.1) do |file, env|
          raise Benchcc::CompilationError.new
        end
      }.not_to raise_error
    end
  }
end