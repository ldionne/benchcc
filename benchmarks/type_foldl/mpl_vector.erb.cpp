#include <boost/mpl/fold.hpp>
<%= Benchcc::MPL::Vector.new(0...depth).includes %>


<%= render('_main.erb') do |f, state, xs|
    "boost::mpl::fold<#{Benchcc::MPL::Vector.new(xs)}, #{state}, #{f}>::type"
end %>