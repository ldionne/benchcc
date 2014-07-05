require 'csv'
require 'gnuplot'


module Benchcc
  def plot_memusg(output, *inputs)
    Gnuplot.open do |io|
      Gnuplot::Plot.new(io) do |plot|
        plot.ylabel   'Memory usage'
        plot.decimal  "locale 'en_US.UTF-8'"
        plot.format   'y "%.2e kb"'
        plot.term     'png'
        plot.output   output
        plot.data = inputs.map { |file|
          csv = CSV.table(file)
          Gnuplot::DataSet.new([csv[:x], csv[:peak_memusg]]) { |ds|
            ds.title = file
            ds.with = 'lines'
          }
        }
      end
    end
  end
  module_function :plot_memusg

  def plot_time(output, *inputs)
    Gnuplot.open do |io|
      Gnuplot::Plot.new(io) do |plot|
        plot.ylabel   'Compilation time'
        plot.format   'y "%.2g s"'
        plot.term     'png'
        plot.output   output
        plot.data = inputs.map { |file|
          csv = CSV.table(file)
          Gnuplot::DataSet.new([csv[:x], csv[:wall_time]]) { |ds|
            ds.title = file
            ds.with = 'lines'
          }
        }
      end
    end
  end
  module_function :plot_time
end