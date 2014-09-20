require 'benchcc/compiler'

require 'pathname'
require 'rspec'
require 'tempfile'


describe Benchcc::Compiler do
  describe :compile_file do
    it {
      class Mock < Benchcc::Compiler
        def compile_code(code); code; end
      end

      file = Tempfile.new('')
      file.write("whatever")
      expect(Mock.new.compile_file(file.path)).to eq(file.read)
    }
  end

  describe :compile_code do
    it {
      class Mock < Benchcc::Compiler
        def compile_file(file); File.read(file); end
      end

      expect(Mock.new.compile_code("whatever")).to eq("whatever")
    }
  end

  describe :guess_from_binary do
    it('can guess clang') {
      expect(
        Benchcc::Compiler.guess_from_binary(`which clang`.strip)
      ).to be_instance_of(Benchcc::Clang)
    }

    # GCC is aliased to clang on OSX, so this test fails.
    # it('can guess gcc') {
    #   expect(
    #     Benchcc::Compiler.guess_from_binary(`which gcc`.strip)
    #   ).to be_instance_of(Benchcc::GCC)
    # }

    it('fails otherwise') {
      expect {
        Benchcc::Compiler.guess_from_binary('not_a_compiler')
      }.to raise_error
    }
  end
end

[[Benchcc::Clang, 'clang++'], [Benchcc::GCC, 'g++']].each do |compiler, which|
  describe compiler do
    before(:each) {
      @cc = compiler.new(which)
      @invalid = Pathname.new('src/invalid.cpp').expand_path(File.dirname(__FILE__))
      @valid = Pathname.new('src/valid.cpp').expand_path(File.dirname(__FILE__))
    }

    describe :compile_file do
      it('fails cleanly on invalid input') {
        expect {
          @cc.compile_file(@invalid)
        }.to raise_error(Benchcc::CompilationError)
      }

      it('returns statistics on valid input') {
        expect(
          @cc.compile_file(@valid, '-o /dev/null')
        ).to be_instance_of(Benchcc::CompilationResult)
      }
    end
  end
end