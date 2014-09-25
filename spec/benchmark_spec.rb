require 'benchcc/benchmark'
require 'benchcc/compiler'

require 'rspec'
require 'tempfile'


describe Benchcc.method(:benchmark) do
  it('should not throw') {
    envs = [{input_size: 1}, {input_size: 2}]
    Tempfile.create('') do |file|
      expect {
        data = Benchcc.benchmark(
          erb_file: file.path,
          environments: [],
          compilation_timeout: 10,
          execution_timeout: 10,
          evaluate_erb_relative_to: '',
          features: [],
          compiler_executable: `which clang++`,
          compiler_id: 'Clang',
          compiler_options: []
        )
      }.not_to raise_error
    end
  }
end