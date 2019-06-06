#include <windows.h>

int main(){
	//MessageBoxA( 0, "Hello World!", "Greetings", 0 );
	MessageBoxW(nullptr, L"Hello World!", L"Greetings", MB_OKCANCEL);
}
