#include <boost/tuple/tuple.hpp>


int main() {
    auto go = boost::make_tuple(<%= (0...depth).to_a.join(', ') %>);
    auto last = boost::get< <%= depth - 1 %>  >(go);
}