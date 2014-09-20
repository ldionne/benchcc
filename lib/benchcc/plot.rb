require 'csv'
require 'gnuplot'


module Benchcc
  Y_FEATURES = [:memory_usage, :compilation_time, :run_time]

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

    run_time: -> (plot) {
      plot.ylabel   'Run time'
      plot.format   'y \'%.2g s\''
    }
  }

  def plot(output, titles, inputs, x_feature: :input_size, y_feature: :compilation_time, &tweak)
    raise ArgumentError if not Benchcc::Y_FEATURES.include?(y_feature)
    tweak ||= Benchcc::DEFAULT_TWEAK[y_feature]

    Gnuplot.open do |io|
      Gnuplot::Plot.new(io) do |plot|
        plot.term     'png'
        plot.output   output
        plot.data = titles.zip(inputs).map { |title, file|
          csv = CSV.table(file)
          Gnuplot::DataSet.new([csv[x_feature], csv[y_feature]]) { |ds|
            ds.title = title
            ds.with = 'lines'
          }
        }
        tweak.call(plot)
      end
    end
  end
  module_function :plot
end