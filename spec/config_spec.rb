require "spec_helper"


describe Benchcc::Config do
  it "allows the id to be a string instead of a symbol" do
    config = Benchcc::Config.new("config_id")
    expect(config.id).to eq(:config_id)
  end


  describe "empty config" do
    before(:each) do
      @config = Benchcc::Config.new(:config_id)
    end

    it "is enabled" do
      expect(@config.enabled? Hash.new).to be_true
      expect(@config.disabled? Hash.new).to be_false
    end

    it "augments the environment with its id" do
      @config.with(Hash.new) do |env|
        expect(env[:config]).to eq(:config_id)
      end
    end
  end


  describe "requires" do
    it "enables the config only when all the predicates are satisfied" do
      config = Benchcc::Config.new(:config_id) do
        requires { |e| e[0] }
        requires { |e| e[1] }
      end

      for env in [true, false].repeated_combination(2)
        expect(config.enabled? env).to eq(env[0] && env[1])
      end
    end

    it "enables the config only when all pairs are in the environment" do
      config = Benchcc::Config.new(:config_id) do
        requires key1: 1, key2: 2
        requires key3: 3
      end

      expect(config.enabled?({key1:1, key2:2, key3:3})).to be_true
      expect(config.enabled?({key1:1, key2:2})).to be_false
      expect(config.enabled?({key1:1, key3:3})).to be_false
      expect(config.enabled?(Hash.new)).to be_false
    end
  end


  describe "env" do
    it "augments the environment with the given pairs" do
      config = Benchcc::Config.new(:config_id) do
        env a: :a
        env b: :b, c: :c
      end

      config.with(Hash.new) do |env|
        expect(env[:a]).to eq(:a)
        expect(env[:b]).to eq(:b)
        expect(env[:c]).to eq(:c)
      end
    end

    it "augments the environment by calling the blocks" do
      config = Benchcc::Config.new(:config_id) do
        env { |e| e.merge({a: :a}) }
        env { |e| e.merge({b: :b}) }
      end

      config.with(Hash.new) do |env|
        expect(env[:a]).to eq(:a)
        expect(env[:b]).to eq(:b)
      end
    end
  end


  describe "compiler" do
    it "enables the config when the right compiler is given" do
      config = Benchcc::Config.new(:config_id) do
        compiler :test_compiler
      end
      expect(config.enabled?({:compiler => :test_compiler})).to be_true
    end

    it "disables the config when the wrong compiler is given" do
      config = Benchcc::Config.new(:config_id) do
        compiler :test_compiler
      end
      expect(config.enabled?({:compiler => :nope})).to be_false
    end

    it "disables the config when no compiler is given" do
      config = Benchcc::Config.new(:config_id) do
        compiler :test_compiler
      end
      expect(config.enabled?(Hash.new)).to be_false
    end
  end


  describe "tweak!" do
    before(:each) do
      @config = Benchcc::Config.new(:config_id)
    end

    it "modifies the object in-place" do
      @config.tweak! { requires { false } }
      expect(@config.enabled? Hash.new).to be_false
    end
  end

end