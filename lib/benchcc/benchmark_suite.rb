require "rake"


module Benchcc
  def benchmark_suite(name, &block)
    extend Rake::DSL

    block ||= proc { }
    ns = namespace(name, &block)
    deps = ns.tasks.map(&:name)
    args = ns.tasks.map(&:arg_names).flatten.uniq
    task(name, args => deps, &block)
  end
  module_function :benchmark_suite
end # module Benchcc