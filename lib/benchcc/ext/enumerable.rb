module Enumerable
  def foldr(state, &block)
    reverse.inject(state) { |state, x| block.call(x, state) }
  end

  alias_method(:foldl, :inject)
end