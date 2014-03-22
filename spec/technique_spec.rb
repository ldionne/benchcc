require "spec_helper"


describe Benchcc::Technique do

  bench = Benchcc::Benchmark.new(:bench)

  describe "creating an empty technique" do
    tech = Benchcc::Technique.new(:technique_id, bench)

    it "is enabled" do
      expect(tech.enabled? nil).to be_true
      expect(tech.disabled? nil).to be_false
    end

    it "has a pretty name" do
      expect(tech.name).to eq("Technique id")
    end

    it "has no description" do
      expect(tech.description).to eq(nil)
    end
  end

  describe "populating a technique" do
    tech = Benchcc::Technique.new(:technique_id, bench) do
      name        "test_name"
      description "test_description"
      requires    { |e| e[0] }
      requires    { |e| e[1] }
      env         { |e| e.merge({:a => :a}) }
      env         { |e| e.merge({:b => :b}) }
    end

    it "is only enabled when all the predicates are satisfied" do
      for env in [true, false].repeated_combination(2)
        expect(tech.enabled? env).to eq(env[0] && env[1])
        expect(tech.disabled? env).to eq(!env[0] || !env[1])
      end
    end

    it "has the specified name and description" do
      expect(tech.name).to eq("test_name")
      expect(tech.description).to eq("test_description")
    end
  end

end