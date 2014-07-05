require 'benchcc/plot'

require 'fileutils'
require 'rspec'


describe 'plots' do
  before :each do
    @tmpdir = Dir.mktmpdir
    @out = File.join(@tmpdir, 'plot.png')
    @csv = Pathname.new('src/plot.csv').expand_path(File.dirname(__FILE__))
  end

  after :each do
    FileUtils.remove_entry(@tmpdir)
  end

  describe Benchcc.method(:plot_memusg) do
    it {
      expect { Benchcc.plot_memusg(@out, @csv) }.not_to raise_error
    }
  end

  describe Benchcc.method(:plot_time) do
    it {
      expect { Benchcc.plot_time(@out, @csv) }.not_to raise_error
    }
  end
end