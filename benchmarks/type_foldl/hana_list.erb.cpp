#include <boost/hana/list.hpp>
#include <boost/hana/type.hpp>


<%= render('_main.erb') do |f, state, xs|
    <<-EOS
    decltype(
        boost::hana::foldl(
            boost::hana::lift<#{f}::apply>,
            boost::hana::type<#{state}>,
            boost::hana::list_t<#{xs.join(', ')}>
        )
    )::type
    EOS
end %>