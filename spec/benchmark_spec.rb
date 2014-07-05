require 'benchcc/benchmark'

require 'rspec'
require 'tempfile'
require 'timeout'


describe Benchcc.method(:benchmark) do
  it('time outs are ignored') {
    timeout = 0.3
    envs = [{time: timeout + 0.1}, {time: timeout - 0.1},
            {time: timeout + 0.2}, {time: timeout - 0.2}]
    Tempfile.create('') do |file|
      file.write('<%= time %>')
      file.flush
      data = Benchcc.benchmark(file.path, envs, timeout: timeout) do |code|
        sleep(code.to_f)
        {time: code.to_f}
      end
      expect(data).to eq(envs.select { |env| env[:time] < timeout })
    end
  }
end