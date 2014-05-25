#include <boost/fusion/algorithm/iteration/fold.hpp>
<%= Benchcc::Fusion::Cons.new(0...depth).includes %>


<%= render('_main.erb') do |f, state, xs|
    cons = Benchcc::Fusion::Cons.new(xs)
    "boost::fusion::fold(#{cons}{}, #{state}, #{f})"
end %>