#include <boost/mpl11/detail/left_folds/variadic.hpp>
#include <boost/mpl11/integer.hpp>


template <typename x, typename y>
using plus = boost::mpl11::integer_c<
    decltype(x::type::value + y::type::value),
    x::type::value + y::type::value
>;

template <typename ...xs>
using sum = boost::mpl11::detail::left_folds::variadic<
    plus, boost::mpl11::int_<0>, xs...
>;

<%= render('_main.erb') %>