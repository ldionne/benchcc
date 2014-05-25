<%= Benchcc::Fusion::List.new(0...depth).includes %>

#include <boost/fusion/algorithm/iteration/fold.hpp>


<%= render('_main.erb') do |f, state, xs|
    list = Benchcc::Fusion::List.new(xs)
    "boost::fusion::fold(#{list}{}, #{state}, #{f})"
end %>