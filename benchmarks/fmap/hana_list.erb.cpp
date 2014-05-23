#include <boost/hana/list.hpp>


template <typename X>
struct _f { };

constexpr struct {
    template <typename X>
    constexpr _f<X> operator()(X) const;
} f{};

<%=
    render('_main.erb') do |xs, breadth, depth|
        xs = xs.map { |x| "#{x}{}" }.join(', ')
        list = "boost::hana::list(#{xs})"
        "static const auto go#{breadth} = boost::hana::fmap(f, #{list});"
    end
%>