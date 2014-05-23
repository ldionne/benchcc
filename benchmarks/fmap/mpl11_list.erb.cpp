#include <boost/mpl11/list.hpp>


struct f {
    using type = f;
    template <typename>
    struct apply { struct type; };
};

<%=
    render('_main.erb') do |xs, breadth, depth|
        list = "boost::mpl11::list<#{xs.join(', ')}>"
        "using go#{breadth} = boost::mpl11::fmap<f, #{list}>::type;"
    end
%>