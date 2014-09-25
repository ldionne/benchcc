require 'benchcc/compiler'

require 'pathname'
require 'rspec'


[['Clang', 'clang++']].each do |compiler_id, executable|
  describe compiler_id do
    before(:each) {
      @cc = Benchcc::which(compiler_id)
      @invalid = Pathname.new('src/invalid.cpp').expand_path(File.dirname(__FILE__))
      @invalid_runtime = Pathname.new('src/invalid_runtime.cpp').expand_path(File.dirname(__FILE__))
      @valid = Pathname.new('src/valid.cpp').expand_path(File.dirname(__FILE__))
    }

    it('fails cleanly on invalid input') {
      expect {
        @cc.call(
          input_file: @invalid,
          features: [],
          compiler_executable: executable,
          compiler_options: [],
          compilation_timeout: 10,
          execution_timeout: 10
        )
      }.to raise_error(Benchcc::CompilationError)
    }

    it('fails cleanly on runtime error') {
      expect {
        @cc.call(
          input_file: @invalid_runtime,
          features: [:execution_time],
          compiler_executable: executable,
          compiler_options: [],
          compilation_timeout: 10,
          execution_timeout: 10
        )
      }.to raise_error(Benchcc::ExecutionError)
    }

    it('returns statistics on valid input') {
      expect(
        @cc.call(
          input_file: @valid,
          features: [:execution_time, :compilation_time, :memory_usage],
          compiler_executable: executable,
          compiler_options: ['-o/dev/null'],
          compilation_timeout: 10,
          execution_timeout: 10
        )
      ).to be_instance_of(Hash)
    }
  end
end