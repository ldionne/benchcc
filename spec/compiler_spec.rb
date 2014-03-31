require "benchcc/compiler"

require "rspec"


def testfile(name)
  File.join(File.dirname(__FILE__), "test", name)
end

describe Benchcc::Compiler do
  describe "default compiler" do
    let(:default) { Benchcc::Compiler[:default] }

    it "is present" do
      expect(Benchcc::Compiler.list.map(&:id)).to include(:default)
    end

    it "can compile stuff" do
      expect { default.compile(testfile("valid.cpp")) }.not_to raise_error
    end

    it "can time compilation" do
      expect { default.time(testfile("valid.cpp")) }.not_to raise_error
    end

    it "can time compilation of a ERB template" do
      expect {
        default.rtime(testfile("valid.cpp"), Hash.new)
      }.not_to raise_error
    end

    it "handles compilation errors gracefully" do
      expect {
        default.compile(testfile("invalid.cpp"))
      }.to raise_error(Benchcc::CompilationError)

      expect {
        default.time(testfile("invalid.cpp"))
      }.to raise_error(Benchcc::CompilationError)

      expect {
        default.rtime(testfile("invalid.cpp"), Hash.new)
      }.to raise_error(Benchcc::CompilationError)
    end
  end
end