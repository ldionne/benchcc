#include <boost/fusion/tuple.hpp>


int main() {
    auto go = boost::fusion::make_tuple(<%= (0...depth).to_a.join(', ') %>);
}
