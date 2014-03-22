require "spec_helper"


describe "Utils" do

  describe "erb_template?" do
    it "handles full paths" do
      expect(Benchcc.erb_template? "/path/to/file.erb").to be_true
      expect(Benchcc.erb_template? "/path/to/file").to be_false
    end

    it "handles multiple extensions" do
      expect(Benchcc.erb_template? "file.erb").to be_true
      expect(Benchcc.erb_template? "file.ext.erb").to be_true
      expect(Benchcc.erb_template? "file.ext1.ext2.erb").to be_true

      expect(Benchcc.erb_template? "file.ext").to be_false
      expect(Benchcc.erb_template? "filerb.ext").to be_false
      expect(Benchcc.erb_template? "file.erbxt").to be_false
      expect(Benchcc.erb_template? "file").to be_false
    end
  end

  describe "configure" do
    it "gives a meaningful name to erb templates" do
      Benchcc.configure("spec/test_files/test.erb.cpp", Hash.new) do |file|
        expect(File.fnmatch?("*.cpp", File.basename(file))).to be_true
      end
    end
  end

end