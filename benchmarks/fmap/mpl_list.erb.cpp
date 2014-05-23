#include <boost/mpl/transform.hpp>
<%= Benchcc::MPL::List.new(0...depth).includes %>


struct f {
    template <typename>
    struct apply { struct type; };
};

<%=
    render('_main.erb') do |xs, breadth, depth|
        list = Benchcc::MPL::List.new(xs)
        "using go#{breadth} = boost::mpl::transform<#{list}, f>::type;"
    end
%>