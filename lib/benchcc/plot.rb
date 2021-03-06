require 'csv'
require 'gnuplot'


module Benchcc
  Y_FEATURES = [:memory_usage, :compilation_time, :execution_time]

  # How do I make this private?
  DEFAULT_TWEAK = {
    memory_usage: -> (plot) {
      plot.ylabel   'Memory usage'
      plot.decimal  'locale \'en_US.UTF-8\''
      plot.format   'y \'%.2e kb\''
    },

    compilation_time: -> (plot) {
      plot.ylabel   'Compilation time'
      plot.format   'y \'%.2g s\''
    },

    execution_time: -> (plot) {
      plot.ylabel   'Execution time'
      plot.format   'y \'%.0f µs\''
    }
  }

  # title:
  #   The title used for the plot.
  #
  # output:
  #   The name of the file in which the plot is written.
  #
  # curves:
  #   An array of hashes of the form
  #     { title: <curve title>, input: <data set file> }
  #   representing the curves to draw on the plot.
  def plot(title, output, curves, x_feature: :input_size, y_feature: :compilation_time, &tweak)
    x_feature, y_feature = x_feature.to_sym, y_feature.to_sym
    raise ArgumentError if not Benchcc::Y_FEATURES.include?(y_feature)
    tweak ||= Benchcc::DEFAULT_TWEAK[y_feature]

    Gnuplot.open do |io|
      Gnuplot::Plot.new(io) do |plot|
        plot.title    title
        plot.term     'png'
        plot.output   output
        plot.data = curves.map { |curve|
          csv = CSV.table(curve[:input])
          ys = csv[y_feature]
          xs = csv[x_feature]

          # Remove trailing nils from the y-axis. nils can arise when e.g.
          # runtime execution failed but we still kept on gathering info
          # for the compilation, so the execution_time column has some
          # trailing empty values.
          ys.pop until ys.last

          # Restrict the x-axis to the number of valid y-axis values.
          xs = xs[0...ys.size]

          Gnuplot::DataSet.new([xs, ys]) { |ds|
            ds.title = curve[:title]
            ds.with = 'lines'
          }
        }
        tweak.call(plot)
      end
    end
  end
  module_function :plot
end