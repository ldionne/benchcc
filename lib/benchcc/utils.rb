require "benchmark"
require "delegate"
require "erb"
require "pathname"
require "tempfile"


# Indents a multiline string.
# Copied from http://makandracards.com/makandra/6087-ruby-indent-a-string.
String.class_eval do
  def indent(count, char = ' ')
    gsub(/([^\n]*)(\n|$)/) do |match|
      last_iteration = ($1 == "" && $2 == "")
      line = ""
      line << (char * count) unless last_iteration
      line << $1
      line << $2
      line
    end
  end
end

# Returns the basename of a file without its last extension.
def File.basename_we(filename)
  File.basename(filename, File.extname(filename))
end

Array.class_eval do
  # Creates a Hash from an Array; the block is used to perform indexing.
  def index_by(&block)
    block ||= -> (x) { x } # the identity function
    Hash[self.zip(self.map(&block))]
  end

  def average
    (self.reduce :+) / self.size
  end
end

Numeric.class_eval do
  def round_up(ndigits)
    k = 10 ** ndigits
    if self % k == 0
      self
    else
      (1 + self/k) * k
    end
  end
end

Hash.class_eval do
  def subsetof?(other)
    (self.to_a - other.to_a).empty?
  end
end

Pathname.class_eval do
  def /(other)
    other = other.to_s if other.kind_of? Symbol
    self + Pathname.new(other)
  end
end

module Benchcc
  module Dsl
    # Creates a Docile-style setter for the given attributes.
    def dsl_setter(*attrs)
      attrs.map(&:to_s).each do |atr|
        define_method(atr) do |value|
          instance_variable_set('@' + atr, value)
        end
      end
    end

    # Same as dsl_setter, but the method may be called without arguments to
    # simply retrieve the value of that attribute.
    def dsl_accessor(*attrs)
      attrs.map(&:to_s).each do |atr|
        define_method(atr) do |value = instance_variable_get('@' + atr)|
          instance_variable_set('@' + atr, value)
        end
      end
    end
  end

  # time: Proc -> Benchmark.Tms
  #
  # Measure the time taken to call the given block.
  #
  # First, the block is called a number of times (default 1) as a rehearsal.
  # Then, it is called again a number of times (default 3) while the time is
  # recorded. The average of these last calls is returned.
  def self.time(repetitions: 3, rehearsals: 1, &f)
    raise ArgumentError, "A block must be given" unless block_given?

    rehearsals.times { f.call }
    repetitions.times
               .collect { ::Benchmark.measure { f.call } }
               .average
  end

  # erb_template?: Path -> Bool
  #
  # Returns whether a path likely represents an ERB template. Basically, we
  # check whether the filename contains a .erb extension. The file may have
  # several extensions (e.g. ".erb.html") as long as it has .erb somewhere.
  def self.erb_template?(file)
    File.fnmatch?("{*.erb.*,*.erb}", File.basename(file), File::FNM_EXTGLOB)
  end

  # configure: Pathname x Hash x Proc -> Result of Proc
  #
  # Call the given block with a path to a configured version of the
  # given filename. If the filename represents an ERB template, it is
  # generated with the given environment. Otherwise, it is yielded as-is.
  def self.configure(filename, env)
    unless File.file? filename
      raise ArgumentError, "Inexistent filename \"#{filename}\""
    end

    if Benchcc.erb_template? filename
      fresh = eval("-> (env) { proc {} }", TOPLEVEL_BINDING).call(env)
      configured = ERB.new(File.read(filename))
      configured.filename = filename
      configured = configured.result(fresh.binding)

      tmp = Tempfile.new([File.basename_we(filename), File.extname(filename)])
      tmp.write(configured)
      tmp.close # flushes the file
      yield tmp.path
    else
      yield filename
    end
  end

  # Proxy object. When the << method is called for the first time, a
  # user supplied block is invoked on the object.
  class OnFirstShift < SimpleDelegator
    def initialize(*args, &on_first_modification)
      super
      @was_modified = false
      @on_first = on_first_modification || proc { }
    end

    def <<(*args)
      if not @was_modified
        @was_modified = true
        @on_first.call(self)
      end
      super
    end
  end
end