# this one is important -> recognizes win-cl as msvc compiler
set(CMAKE_SYSTEM_NAME Windows) #
set(CMAKE_SYSTEM_VERSION 1)

# specify the cross compiler
set(CMAKE_C_COMPILER   /home/df0/Workspace/vs/wine-cl)
set(CMAKE_CXX_COMPILER /home/df0/Workspace/vs/wine-cl)
set(CMAKE_LINKER       /home/df0/Workspace/vs/wine-link)
set(CMAKE_RC_COMPILER  /home/df0/Workspace/vs/wine-rc)
set(CMAKE_MT_COMPILER  /home/df0/Workspace/vs/wine-mt)
# where is the target environment
#set(CMAKE_FIND_ROOT_PATH  /home/df0/Workspace/vs/vs/Microsoft Visual Studio/2019/)

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

