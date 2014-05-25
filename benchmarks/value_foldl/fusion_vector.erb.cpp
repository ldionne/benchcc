<%= Benchcc::Fusion::Vector.new(0...depth).includes %>

#include <boost/fusion/algorithm/iteration/fold.hpp>


<%= render('_main.erb') do |f, state, xs|
    vector = Benchcc::Fusion::Vector.new(xs)
    "boost::fusion::fold(#{vector}{}, #{state}, #{f})"
end %>