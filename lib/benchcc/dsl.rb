require "benchcc/benchmark"
require "benchcc/benchmark_suite"


module Benchcc
  module DSL
      include Benchcc
      module_function :benchmark, :benchmark_suite
      public :benchmark, :benchmark_suite
  end
end

extend Benchcc::DSL