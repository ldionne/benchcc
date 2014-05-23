#include <boost/fusion/algorithm/iteration/fold.hpp>
<%= Benchcc::Fusion::Cons.new(0...depth).includes %>


template <typename ...>
struct result { };

constexpr struct {
    template <typename State, typename X>
    constexpr result<State, X> operator()(State, X) const;
} f{};

<%= (0...breadth).map { |breadth|
    xs = (0...depth).map { |depth| "x#{breadth}<#{depth}>" }
    cons = Benchcc::Fusion::Cons.new(xs)
    <<-EOS
    constexpr struct { } state#{breadth}{};
    template <int> struct x#{breadth} { };
    static const #{cons} cons{};
    static const auto go#{breadth} = boost::fusion::fold(cons, state#{breadth}, f);
    EOS
}.join("\n") %>