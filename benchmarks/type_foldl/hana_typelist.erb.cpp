#include <boost/hana/type.hpp>
#include <boost/hana/typelist.hpp>


<%= render('_main.erb') do |f, state, xs|
    <<-EOS
    decltype(
        boost::hana::foldl(
            boost::hana::lift<#{f}::apply>,
            boost::hana::type<#{state}>,
            boost::hana::typelist<#{xs.join(', ')}>
        )
    )::type
    EOS
end %>