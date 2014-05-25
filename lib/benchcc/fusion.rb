require_relative 'ext/enumerable'
require_relative 'ext/numeric'
require 'delegate'


module Benchcc
  module Fusion
    class List < SimpleDelegator
      def includes
        inc = ["#define FUSION_MAX_LIST_SIZE 50"]
        inc << headers.map { |hdr| "#include <#{hdr}>" }
        inc.join("\n")
      end

      def headers
        ["boost/fusion/container/list/list.hpp"]
      end

      def to_s
        "boost::fusion::list<#{join(', ')}>"
      end
    end

    class Cons < SimpleDelegator
      def includes
        headers.map { |hdr| "#include <#{hdr}>" }.join("\n")
      end

      def headers
        ["boost/fusion/container/list/cons.hpp"]
      end

      def to_s
        foldr('boost::fusion::nil_') do |head, tail|
          "boost::fusion::cons<#{head}, #{tail}>"
        end
      end
    end

    class Vector < SimpleDelegator
      def includes
        headers.map { |hdr| "#include <#{hdr}>" }.join("\n")
      end

      def headers
        ["boost/fusion/container/vector/vector#{[10, size.round_up(1)].max}.hpp"]
      end

      def to_s
        "boost::fusion::vector#{size}<#{join(', ')}>"
      end
    end
  end
end