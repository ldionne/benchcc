require "spec_helper"


describe Benchcc::Compiler do

  describe "creating a new compiler" do
    cc = Benchcc::Compiler.new(:test) { }

    it "makes it available" do
      expect(Benchcc::Compiler.available? :test).to be_true
    end

    it "puts it in the list of available compilers" do
      expect(Benchcc::Compiler.list).to include(:test)
    end

    it "makes the compiler object reachable from its id" do
      expect(Benchcc::Compiler[:test]).to eq(cc)
    end
  end

  describe "compiling a file" do
    it "throws an exception when compilation fails" do
      cc = Benchcc::Compiler.new(:test2) { `exit 1` }
      expect { cc.compile(nil) }.to raise_error
    end
  end

end