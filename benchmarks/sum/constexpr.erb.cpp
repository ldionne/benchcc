#include <boost/mpl11/integer.hpp>


using size_t = decltype(sizeof(int));

constexpr struct plus_ {
    template <typename X, typename Y>
    constexpr auto operator()(X x, Y y) { return x + y; }
} plus{};

template <typename T, size_t N, typename F, typename State>
constexpr State homogeneous_foldl(F f, State s, const T (&array)[N]) {
    for (size_t i = 0; i < N; ++i)
        s = f(s, array[i]);
    return s;
}

template <typename ...xs>
using sum = boost::mpl11::integer_c<
    decltype(homogeneous_foldl<size_t, sizeof...(xs)>(plus, 0, {xs::value...})),
    homogeneous_foldl<size_t, sizeof...(xs)>(plus, 0, {xs::value...})
>;

<%= render('_main.erb') %>