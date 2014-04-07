require "benchcc/benchmark"
require "benchcc/compiler"

require "rake"
require "rspec"


def testfile(name)
  File.join(File.dirname(__FILE__), "test", name)
end

describe Benchcc::Benchmark do
  before(:each) { Rake::Task.clear }

  describe "input_file" do
    context "is set explicitly" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.input_file = "filename"
        end
      }

      it "returns the specified filename" do
        expect(@bm.input_file).to eq("filename")
      end
    end

    context "top level benchmark" do
      before { @bm = Benchcc.benchmark "test" }
      it { expect(@bm.input_file).to eq("test") }
    end

    context "1-deep nested benchmark" do
      before {
        extend Rake::DSL
        namespace(:d1) { @bm = Benchcc.benchmark "test" }
      }
      it { expect(@bm.input_file).to eq("d1/test") }
    end

    context "2-deep nested benchmark" do
      before {
        extend Rake::DSL
        namespace(:d1) {
          namespace(:d2) { @bm = Benchcc.benchmark "test" }
        }
      }
      it { expect(@bm.input_file).to eq("d1/d2/test") }
    end
  end

  describe "output_chart" do
    context "is set explicitly" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.output_chart = "chartfile"
        end
      }

      it "returns the specified filename" do
        expect(@bm.output_chart).to eq("chartfile")
      end
    end

    context "it is not set explicitly" do
      before { @bm = Benchcc.benchmark "test" }

      it "defaults to the input_file with a png extension" do
        expect(@bm.output_chart).to eq("test.png")
      end
    end
  end

  describe "require_" do
    context "no predicates" do
      before { @bm = Benchcc.benchmark "test" }

      it "is always enabled" do
        expect(@bm.enabled? Hash.new).to be_true
      end
    end

    context "strict predicates" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.require_ { param1 }
          bm.require_ { param2 }
        end
      }

      it do
        expect(@bm.enabled? Hash.new).to be_false
        expect(@bm.enabled?({param1: true})).to be_false
        expect(@bm.enabled?({param2: true})).to be_false
        expect(@bm.enabled?({param1: true, param2: true})).to be_true
      end
    end

    context "loose predicate" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.require_{ key1 =~ /1$/ && key2 == :value2 }
        end
      }

      it {
        expect(@bm.enabled? Hash.new).to be_false
        expect(@bm.enabled?({key1: :ue1})).to be_false
        expect(@bm.enabled?({key2: :value2})).to be_false

        expect(@bm.enabled?({key1: :foo, key2: :foo})).to be_false
        expect(@bm.enabled?({key1: :foo, key2: :value2})).to be_false
        expect(@bm.enabled?({key1: :ue1, key2: :foo})).to be_false
        expect(@bm.enabled?({key1: :ue1, key2: :value2})).to be_true
      }
    end
  end

  describe "if_" do
    it "raises when called without block" do
      expect { Benchcc.benchmark("test") { |bm| bm.if_ } }.to raise_error
    end

    context "strict condition disable" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.if_{ key1 == :value1 || key2 == :value2 }.disable
        end
      }

      it do
        expect(@bm.enabled? Hash.new).to be_true

        expect(@bm.enabled?({key1: :foo})).to be_true
        expect(@bm.enabled?({key1: :value1})).to be_false

        expect(@bm.enabled? key2: :foo).to be_true
        expect(@bm.enabled? key2: :value2).to be_false

        expect(@bm.enabled? key1: :foo,    key2: :foo).to be_true
        expect(@bm.enabled? key1: :foo,    key2: :value2).to be_false
        expect(@bm.enabled? key1: :value1, key2: :foo).to be_false
        expect(@bm.enabled? key1: :value1, key2: :value2).to be_false
      end
    end

    context "loose condition disable" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.if_{ key1 =~ /1$/ || key2 =~ /2$/ }.disable
        end
      }

      it do
        expect(@bm.enabled? Hash.new).to be_true

        expect(@bm.enabled? key1: :foo).to be_true
        expect(@bm.enabled? key1: :foo1).to be_false

        expect(@bm.enabled? key2: :foo).to be_true
        expect(@bm.enabled? key2: :foo2).to be_false

        expect(@bm.enabled? key1: :foo,  key2: :foo).to be_true
        expect(@bm.enabled? key1: :foo,  key2: :foo2).to be_false
        expect(@bm.enabled? key1: :foo1, key2: :foo).to be_false
        expect(@bm.enabled? key1: :foo1, key2: :foo2).to be_false
      end
    end

    context "strict condition require" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.if_ { param1 }.require_ { param2 }
        end
      }

      it do
        expect(@bm.enabled? Hash.new).to be_true
        expect(@bm.enabled?({param1: false})).to be_true
        expect(@bm.enabled?({param2: false})).to be_true
        expect(@bm.enabled?({param1: true, param2: true})).to be_true
        expect(@bm.enabled?({param1: true, param2: false})).to be_false
      end
    end

    context "chained require" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.if_ { k1 }.require_ { k2 }.require_ { k3 }
        end
      }

      it do
        expect(@bm.enabled? Hash.new).to be_true
        expect(@bm.enabled?({k1: false})).to be_true

        expect(@bm.enabled?({k1: true, k2: true, k3: true})).to be_true
        expect(@bm.enabled?({k1: true, k2: false, k3: true})).to be_false
        expect(@bm.enabled?({k1: true, k2: true, k3: false})).to be_false
        expect(@bm.enabled?({k1: true, k2: false, k3: false})).to be_false
      end
    end

    describe "context is passed as an argument too" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.if_{ |ctx| ctx.foo }.require_{ |ctx| ctx.bar }
        end
      }

      it do
        expect(@bm.enabled? Hash.new).to be_true

        expect(@bm.enabled?({foo: true})).to be_false
        expect(@bm.enabled?({foo: false})).to be_true
        expect(@bm.enabled?({bar: true})).to be_true
        expect(@bm.enabled?({bar: false})).to be_true

        expect(@bm.enabled?({foo: true, bar: true})).to be_true
        expect(@bm.enabled?({foo: true, bar: false})).to be_false
        expect(@bm.enabled?({foo: false, bar: true})).to be_true
        expect(@bm.enabled?({foo: false, bar: false})).to be_true
      end
    end
  end

  describe "variants" do
    context "no variants were registered" do
      before { @bm = Benchcc.benchmark "test" }

      it "has no variants" do
        expect(@bm.all_variants.empty?).to be_true
      end
    end

    context "variants were registered" do
      before {
        @bm = Benchcc.benchmark "test" do |bm|
          bm.variant :param1, [:a, :b]
          bm.variant :param2, [:c, :d]
        end
      }

      it "generates all combinations" do
        expect(@bm.all_variants).to include(
          {param1: :a, param2: :c},
          {param1: :a, param2: :d},
          {param1: :b, param2: :c},
          {param1: :b, param2: :d}
        )
      end
    end
  end

  describe "plot" do
    before {
      @valid_cpp, @valid_png = testfile("valid.cpp"), testfile("valid.png")
      @bm = Benchcc.benchmark @valid_cpp do |bm|
        bm.variant :variant1, [:value1, :value2]
        bm.plot 0.upto 1
      end
    }

    context "with specified compiler" do
      it "creates a pretty graph" do
        args = Rake::TaskArguments.new([:compiler], [:default])
        expect { @bm.execute(args) }.not_to raise_error
        expect(File.file? @valid_png).to be_true
      end
    end

    context "without specifying a compiler" do
      it "creates a pretty graph" do
        expect { @bm.execute }.not_to raise_error
        expect(File.file? @valid_cpp).to be_true
      end
    end

    after { File.delete(@valid_png) if File.exists? @valid_png }
  end
end