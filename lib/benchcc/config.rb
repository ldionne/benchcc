require "docile"


module Benchcc
  class Config
    # Creates a new configuration with the given id.
    #
    # If a block is given, it is used to populate the remaining attributes of
    # the config by calling `tweak!`.
    def initialize(id, &block)
      @id = id.to_sym
      @predicates = []
      @modifs = []
      self.tweak!(&block) if block_given?
    end

    # tweak!: Proc -> Nil
    #
    # Yields the config to the block, allowing it to be modified in-place
    # using Docile-style attributes.
    def tweak!(&block)
      Docile.dsl_eval(self, &block)
    end

    # id: Symbol
    #
    # Token uniquely identifying the config within a benchmark.
    attr_reader :id

    # requires: Hash x Proc -> Nil
    #
    # Specify conditions that must be met in order for this configuration to
    # be enabled.
    #
    # If `key => value` pairs are passed to the method, the environment must
    # include those pairs for the configuration to be enabled. If a block is
    # given, it is taken as a predicate (to be called on the environment) that
    # must be satisfied for the configuration to be enabled.
    #
    # By default, the configuration is always enabled. Calling this method
    # several times will cause the configuration to be enabled when all the
    # registered conditions are satisfied.
    def requires(**keys, &predicate)
      predicate ||= proc { true }
      @predicates << -> (env) { keys.subsetof?(env) && predicate.call(env) }
    end

    # compiler: Symbol(s) -> Nil
    #
    # Require the compiler to be one of the given `compiler_ids` for this
    # config to be enabled.
    def compiler(*compiler_ids)
      self.requires { |env| compiler_ids.include?(env[:compiler]) }
    end

    # enabled?: Hash -> bool
    #
    # Returns whether the config is enabled in the specified environment.
    def enabled?(env)
      @predicates.all? { |pred| pred.call(env) }
    end

    # disabled?: Hash -> bool
    #
    # Negates the enabled? method; provided for convenience.
    def disabled?(env)
      !self.enabled? env
    end

    # env: Hash x Proc -> Nil
    #
    # Specify modifications to perform on the environment before the
    # configuration is benchmarked.
    #
    # If `key => value` pairs may are passed to the method, they are merged
    # into the environment. If a block is given, it is called with the
    # environment before the config is benchmarked and may return it modified.
    # If the method is called several times, the modifications to perform on
    # the environment are all performed in their registration order.
    def env(**keys, &modifs)
      modifs ||= proc { |env| env }
      @modifs << -> (env) { modifs.call(env.merge(keys)) }
    end

    # with: Hash -> ...
    #
    # Augment the environment with the registered modifications and yield
    # to the block. This method also augments the environment with
    # `:config => self.id`.
    def with(env)
      env = env.merge(config: self.id)
      env = @modifs.reduce(env) { |e, modif| modif.call(e) }
      yield env
    end

    def to_s
      self.id.to_s
    end
  end # class Technique
end # module Benchcc