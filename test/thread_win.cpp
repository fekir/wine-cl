#include <windows.h>

#include <thread>
#include <chrono>

DWORD WINAPI foo(LPVOID){
    // simulate expensive operation
	std::this_thread::sleep_for(std::chrono::seconds(1));
	return 0;
}

int main(){
	HANDLE h = CreateThread(nullptr, 0, foo, nullptr, 0, nullptr);
	WaitForSingleObject(h, INFINITE);
	CloseHandle(h);
}
