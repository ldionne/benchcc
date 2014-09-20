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

  describe Benchcc.method(:plot) do
    Benchcc::Y_FEATURES.each do |feature|
      it {
        expect {
          Benchcc.plot(@out, [''], [@csv], y_feature: feature)
        }.not_to raise_error
      }
    end
  end
end