require 'delegate'


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

# Returns the basename of a file without the extension.
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