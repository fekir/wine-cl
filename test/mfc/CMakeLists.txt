cmake_minimum_required(VERSION 3.13)

project(cmake-test-mfc VERSION 1.0.0 LANGUAGES CXX)

# https://gitlab.kitware.com/cmake/community/wikis/FAQ#how-to-use-mfc-with-cmake
#1: Use MFC in a Static Library
#2: Use MFC in a Shared DLL
set(CMAKE_MFC_FLAG 1) # FIXME: target option?

set(SOURCE_FILES
	mydialog.hpp
	mydialog.cpp
)

set(RES_FILES
	resource.rc
	resource.h
)

add_executable(${PROJECT_NAME} WIN32
	main.hpp main.cpp
	${SOURCE_FILES}
	${RES_FILES}
)

target_compile_definitions(${PROJECT_NAME} PUBLIC
	WIN32_LEAN_AND_MEAN                 # removes rarely used header from windows.h (simply include those headers when needed)
	NOMINMAX                            # removes min and max macro, use std::min and std::max
	STRICT                              # enable strict mode (more type safety)

	# set minimal version of windows
	NTDDI_VERSION=NTDDI_VISTA           
	_WIN32_WINNT=_WIN32_WINNT_VISTA
	WINVER=_WIN32_WINNT_VISTA

	# use UNICODE API by default, the ANSI API behaves incorrectly when using letters outside from local codepage
	_UNICODE UNICODE                    

	_ATL_CSTRING_EXPLICIT_CONSTRUCTORS  # make CString constructor explicit
	_ATL_ALL_WARNINGS                   # otherwise ATL may globally disable some warning
	_SECURE_ATL=1
	#_AFXDLL # add if CMAKE_MFC_FLAG == 1

	# https://stackoverflow.com/questions/59635/app-does-not-run-with-vs-2008-sp1-dlls-previous-version-works-with-rtm-versions
	_BIND_TO_CURRENT_CRT_VERSION
	_BIND_TO_CURRENT_MFC_VERSION
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    LINK_FLAGS "/ENTRY:\"wWinMainCRTStartup\""
)

# FIXME: remove /MD flags and replace with /MT instead of appending, if CMAKE_MFC_FLAG == 1
target_compile_options(${PROJECT_NAME}
	PUBLIC
		$<$<CONFIG:Debug>:/MTd>
		$<$<CONFIG:RelWithDebInfo>:/MTd>
		$<$<CONFIG:MinSizeRel>:/MTd>
		$<$<CONFIG:Release>:/MT>
)
