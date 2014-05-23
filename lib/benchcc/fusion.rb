require_relative 'ext/enumerable'
require 'delegate'


module Benchcc
  module Fusion
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
  end
end