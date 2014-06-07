#include <boost/hana/list.hpp>


int main() {
    auto go = boost::hana::list(<%= (0...depth).to_a.join(', ') %>);
}
