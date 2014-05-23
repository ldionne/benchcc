require_relative 'ext/numeric'
require 'delegate'


module Benchcc
  module MPL
    class Sequence < SimpleDelegator
      def includes
        headers.map { |hdr| "#include <#{hdr}>" }.join("\n")
      end

      def headers(name)
        [
          "boost/mpl/#{name}/#{name}#{[size.round_up(1), 50].min}.hpp",
          size > 50 ? "boost/mpl/#{name}/aux_/item.hpp" : nil
        ].compact
      end
    end

    class Vector < Sequence
      def to_s
        initial, rest = map(&:to_s).take(50), map(&:to_s).drop(50)
        vectorN = "boost::mpl::vector#{initial.size}<#{initial.join(', ')}>"
        rest.reduce(vectorN) do |tail, x|
          "boost::mpl::v_item<#{x}, #{tail}, 0>" # we emulate mpl::push_back
        end
      end

      def headers; super 'vector'; end
    end

    class List < Sequence
      def to_s
        tail = map(&:to_s).last(50)
        init = map(&:to_s).first([size - tail.size, 0].max)
        listN = "boost::mpl::list#{tail.size}<#{tail.join(', ')}>"

        init.reverse.zip(51..Float::INFINITY).reduce(listN) do |tail, x_size|
          x, size = x_size
          # we emulate mpl::push_front
          "boost::mpl::l_item<boost::mpl::long_<#{size}>, #{x}, #{tail}>"
        end
      end

      def headers; super 'list'; end
    end
  end
end