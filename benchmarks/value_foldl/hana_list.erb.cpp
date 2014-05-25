#include <boost/hana/list.hpp>

<%= render('_main.erb') do |f, state, xs|
    xs = xs.map { |x| "#{x}{}" }.join(', ')
    "boost::hana::foldl(#{f}, #{state}, boost::hana::list(#{xs}))"
end %>