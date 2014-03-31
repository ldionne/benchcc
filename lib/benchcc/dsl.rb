require "benchcc/benchmark"


module Benchcc
  module DSL
      include Benchcc
      module_function :benchmark
      public :benchmark
  end
end

extend Benchcc::DSL