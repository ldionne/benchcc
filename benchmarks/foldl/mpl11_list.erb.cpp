#define BOOST_MPL11_NO_ASSERTIONS
#include <boost/mpl11/list.hpp>


<%= render('_puretype.erb') do |f, state, xs|
    "boost::mpl11::foldl<#{f}, #{state}, boost::mpl11::list<#{xs.join(', ')}>>"
end %>