#include <boost/mpl/fold.hpp>
<%= Benchcc::MPL::List.new(0...depth).includes %>


<%= render('_main.erb') do |f, state, xs|
    "boost::mpl::fold<#{Benchcc::MPL::List.new(xs)}, #{state}, #{f}>::type"
end %>