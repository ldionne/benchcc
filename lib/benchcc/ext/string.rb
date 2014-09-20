class String
  def quote(char = '"')
    char + self + char
  end

  # Strip leading whitespace from each line that is the same as the
  # amount of whitespace on the first line of the string.
  # Leaves _additional_ indentation on later lines intact.
  def strip_heredoc
    gsub /^#{self[/\A\s*/]}/, ''
  end
end