#include <vector>
#include <iostream>
#include <iterator>

int main(){
	auto vec = std::vector<int>(std::istream_iterator<int>(std::cin), std::istream_iterator<int>());
	std::cout << "Number of elements: " << vec.size() << "\nValues:\n ";
	for(const auto& v : vec){
		std::cout  << v << ", ";
	}
    std::cout << '\n';
}

