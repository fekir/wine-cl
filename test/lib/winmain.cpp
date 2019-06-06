#include <iostream>

#include "lib.hpp"

//#include <winbase.h>
#include <Windows.h>

int WinMain(HINSTANCE, HINSTANCE, LPSTR, int) {
	std::cout << "Hello World (C++, WinMain, lib)!\n";
	return testlib(0);
}
