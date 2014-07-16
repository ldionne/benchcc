require 'benchcc/benchmark'

require 'rspec'
require 'tempfile'
require 'timeout'


describe Benchcc.method(:benchmark) do
  it('should stop on timeout') {
    timeout = 0.3
    envs = [{time: timeout - 0.1}, {time: timeout + 0.1}, {time: timeout - 0.2}]
    Tempfile.create('') do |file|
      file.write('<%= time %>') && file.flush
      devnull = File.open(File::NULL, 'w')

      data = Benchcc.benchmark(file.path, envs, timeout: timeout, stderr: devnull) do |code|
        sleep(code.to_f)
        {time: code.to_f}
      end
      expect(data).to eq(envs.take_while { |env| env[:time] < timeout })
    end
  }

  it('should accumulate whatever is returned from the block') {
    envs = [{x: 0}, {x: 1}, {x: 2}, {x: 3}]
    Tempfile.create('') do |file|
      file.write('<%= x %>')
      file.flush
      data = Benchcc.benchmark(file.path, envs) do |x|
        {x: x.to_i}
      end
      expect(data).to eq(envs)
    end
  }
end

describe Benchcc.method(:benchmark_to_csv) do
  it('should output to csv correctly') {
    envs = [{x: 1, y:-1}, {x: 2, y:-2}, {x: 3, y:-3}]
    Tempfile.create('') do |file|
      file.write('<%= x %> <%= y %>')
      file.flush
      csv = Benchcc.benchmark_to_csv(file.path, envs) do |str|
        x, y = str.split(' ')
        {x: x.to_i, y: y.to_i}
      end
      expect(csv).to eq("x,y\n1,-1\n2,-2\n3,-3\n")
    end
  }
end