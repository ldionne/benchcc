require 'benchcc/plot'

require 'fileutils'
require 'rspec'


describe 'plots' do
  before :each do
    @tmpdir = Dir.mktmpdir
    @out = File.join(@tmpdir, 'plot.png')
    @csv = Pathname.new('src/plot.csv').expand_path(File.dirname(__FILE__))
    @partial_csv = Pathname.new('src/partial_plot.csv').expand_path(File.dirname(__FILE__))
  end

  after :each do
    FileUtils.remove_entry(@tmpdir)
  end

  describe Benchcc.method(:plot) do
    Benchcc::Y_FEATURES.each do |feature|
      it ("does not explode") {
        curves = [{title: 'curve title', input: @csv}]
        expect {
          Benchcc.plot('plot title', @out, curves, y_feature: feature)
        }.not_to raise_error
      }

      it ("does not explode when points are missing") {
        curves = [{title: 'curve title', input: @partial_csv}]
        expect {
          Benchcc.plot('plot title', @out, curves, y_feature: feature)
        }.not_to raise_error
      }
    end
  end
end