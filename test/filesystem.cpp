#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

int main()
{
    fs::path p = fs::current_path();

    std::cout << "\tThe current path " << p << " decomposes into:\n"
              << "\troot name " << p.root_name() << '\n'
              << "\troot directory " << p.root_directory() << '\n'
              << "\trelative path " << p.relative_path() << '\n';
}
