#include <tuple>


int main() {
    auto go = std::make_tuple(<%= (0...depth).to_a.join(', ') %>);
    auto last = std::get< <%= depth - 1 %>  >(go);
}
