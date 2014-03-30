require "benchmark"
require "erb"
require "ostruct"
require "tempfile"


class Array
  def average
    (self.reduce :+) / self.size
  end
end

class Numeric
  # round_up: Numeric -> Numeric
  #
  # Round up the integer to a given precision in decimal digits (default 0
  # digits). This is similar to `round`, except that rounding is always done
  # upwards.
  def round_up(ndigits = 0)
    k = 10 ** ndigits
    if self % k == 0
      self
    else
      (1 + self/k) * k
    end
  end
end

class Tempfile
  def self.with(content, hints)
    tmp = new(hints)
    tmp.write(content)
    tmp.flush
    return yield tmp
  ensure
    tmp.close!
  end
end

module Benchcc
  module Utility
    # hash_product: Hash -> Hashes
    def hash_product(hash)
      values = hash.values.map(&:to_a)
      return [] if values.empty?
      values[0].product(*values[1..-1]).map { |p|
        Hash[hash.keys.zip(p)]
      }
    end
    module_function :hash_product

    # from_erb: Path x Hash or OpenStruct -> String
    #
    # Run ERB on the `input_file` with the given environment and return
    # the result of the generation.
    #
    # The environment is converted to an `OpenStruct` and the ERB template
    # is evaluated in a top level binding where `env` refers to the given
    # environment.
    def from_erb(input_file, env)
      env = OpenStruct.new(env)
      unless File.file? input_file
        raise ArgumentError, "invalid input file \"#{input_file}\""
      end

      fresh = eval("-> (env) { proc {} }", TOPLEVEL_BINDING).call(env)
      erb = ERB.new(File.read(input_file))
      erb.filename = input_file
      return erb.result(fresh.binding)
    end
    module_function :from_erb

    # time: Proc -> ::Benchmark.Tms
    #
    # Measure the time taken to call the given block.
    #
    # First, the block is called a number of times (default 1) as a rehearsal.
    # Then, it is called again a number of times (default 3) while the time is
    # recorded. The average of these last calls is returned.
    def time(repetitions: 3, rehearsals: 1, &f)
      raise ArgumentError, "a block must be given" unless block_given?

      rehearsals.times { f.call }
      repetitions.times
                 .collect { ::Benchmark.measure { f.call } }
                 .average
    end
    module_function :time
  end # module Utility
end # module Benchcc


=begin
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
=end