require 'gnuplot'


class Gnuplot::DataSet
  def self.from_file(file, using: [1, 2], &block)
    self.new("\"#{file}\" using #{using.join(':')}", &block)
  end
end