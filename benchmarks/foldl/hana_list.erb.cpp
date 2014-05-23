#include <boost/hana/list.hpp>


template <typename ...>
struct result { };

constexpr struct {
    template <typename State, typename X>
    constexpr result<State, X> operator()(State, X) const;
} f{};

<%= (0...breadth).map { |breadth|
    xs = (0...depth).map { |depth| "x#{breadth}<#{depth}>{}" }.join(', ')
    <<-EOS
    constexpr struct { } state#{breadth}{};
    template <int> struct x#{breadth} { };
    static const auto go#{breadth} = boost::hana::foldl(f, state#{breadth}, boost::hana::list(#{xs}));
    EOS
}.join("\n") %>