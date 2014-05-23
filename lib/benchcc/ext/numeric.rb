class Numeric
  # round_up: Numeric -> Numeric
  #
  # Round up the integer to a given precision in decimal digits (default 0
  # digits). This is similar to `round`, except that rounding is always done
  # upwards.
  def round_up(ndigits = 0)
    k = 10 ** ndigits
    if self % k == 0
      self
    else
      (1 + self/k) * k
    end
  end
end