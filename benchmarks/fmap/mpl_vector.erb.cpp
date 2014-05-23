#include <boost/mpl/transform.hpp>
<%= Benchcc::MPL::Vector.new(0...depth).includes %>


struct f {
    template <typename>
    struct apply { struct type; };
};

<%=
    render('_main.erb') do |xs, breadth, depth|
        vector = Benchcc::MPL::Vector.new(xs)
        "using go#{breadth} = boost::mpl::transform<#{vector}, f>::type;"
    end
%>