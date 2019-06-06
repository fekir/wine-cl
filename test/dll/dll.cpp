#include "dll.h"

#include <iostream>

int testdll(int a) {
    std::cout << "Hello library\n";
	return a;
}

