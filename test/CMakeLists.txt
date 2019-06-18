cmake_minimum_required(VERSION 3.13)

project(cmake-test)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # only with make and ninja...

add_executable(${PROJECT_NAME}-maincpp main.cpp)
add_executable(${PROJECT_NAME}-maincpp-win WIN32 winmain.cpp)

add_executable(${PROJECT_NAME}-mainc main.c)

add_executable(${PROJECT_NAME}-macro macro.c)
target_compile_definitions(${PROJECT_NAME}-macro PRIVATE CICCIA=1)

add_executable(${PROJECT_NAME}-filesystem filesystem.cpp)
set_target_properties(${PROJECT_NAME}-filesystem PROPERTIES CXX_STANDARD 17)

add_executable(${PROJECT_NAME}-thread thread.cpp)
set_target_properties(${PROJECT_NAME}-thread PROPERTIES CXX_STANDARD 11)

add_executable(${PROJECT_NAME}-thread-win thread_win.cpp)

add_executable(${PROJECT_NAME}-messagebox messagebox.cpp)

add_library(${PROJECT_NAME}-dll SHARED lib/lib.cpp lib/lib.hpp)
add_library(${PROJECT_NAME}-lib STATIC lib/lib.cpp lib/lib.hpp)

add_executable(${PROJECT_NAME}-withlib lib/main.cpp)
target_link_libraries(${PROJECT_NAME}-withlib ${PROJECT_NAME}-lib)

add_executable(${PROJECT_NAME}-maincpp-win-withlib WIN32 lib/winmain.cpp)
target_link_libraries(${PROJECT_NAME}-maincpp-win-withlib ${PROJECT_NAME}-lib)



#include (GenerateExportHeader)
#target_include_directories(${PROJECT_NAME}-lib-shared SYSTEM PUBLIC "${CMAKE_BINARY_DIR}")
#target_include_directories(${PROJECT_NAME}-lib-static SYSTEM PUBLIC "${CMAKE_BINARY_DIR}")
#generate_export_header(${PROJECT_NAME}-lib-shared
#    BASE_NAME lib
#    EXPORT_MACRO_NAME LIB_EXPORTS
#    EXPORT_FILE_NAME lib_exports.h
#    STATIC_DEFINE SHARED_EXPORTS_BUILT_AS_STATIC
#)
#set_target_properties(${PROJECT_NAME}-lib-static PROPERTIES COMPILE_FLAGS -DLIBSHARED_AND_STATIC_STATIC_DEFINE)

if (CMAKE_SIZEOF_VOID_P EQUAL 8)
	add_subdirectory(mfc)
else ()
	# does not build with x86 cl, test program including afxwin.h and nothing else generates ICE
endif ()
