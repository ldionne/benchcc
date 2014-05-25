#define BOOST_MPL11_NO_ASSERTIONS
#include <boost/mpl11/list.hpp>


<%= render('_main.erb') do |f, state, xs|
    list = "boost::mpl11::list<#{xs.join(', ')}>"
    "boost::mpl11::foldl<#{f}, #{state}, #{list}>::type"
end %>