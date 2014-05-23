class String
  def quote(char = '"')
    char + self + char
  end
end