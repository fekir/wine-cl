#include <iostream>

#include "lib.hpp"

#include <Windows.h>

int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int) {
	std::cout << "Hello World (C++, WinMain, lib)!\n";
	return testlib(0);
}
