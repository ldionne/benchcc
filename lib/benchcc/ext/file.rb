require 'pathname'


class File
  def self.remove_ext(path)
    path.chomp(extname(path))
  end

  def self.sub_ext(path, ext)
    Pathname.new(path).sub_ext(ext).to_path
  end

  def self.basename_we(path)
    File.basename(File.remove_ext(path))
  end
end