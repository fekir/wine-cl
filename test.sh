#!/bin/sh

set -o errexit
set -o nounset


cl="$1"; shift;
link="$1"; shift;
lib="$1"; shift;
rc="$1"; shift;
mt="$1"; shift;

TMPDIR=${XDG_RUNTIME_DIR:-${TMPDIR:-${TMP:-${TEMP:-/tmp}}}}
BUILDDIR="$(mktemp -p "$TMPDIR" -d test-msvc.XXXXXX.d)";
trap 'rm -r -- "$BUILDDIR"' INT QUIT EXIT;
outfile="$BUILDDIR/a.out"
fo="/Fo/$BUILDDIR/"
out="/out:$outfile"

# fixme: compile every program in separate folder...
compile(){
  "$cl" /nologo /EHsc "$fo" "$@" /link "$out";
}

compile_and_exec(){
  BUILDDIR2="$(mktemp -p "$BUILDDIR" -d test-cl.i.XXXXXX.d)";
  outfile2="$BUILDDIR2/a.out";
  fo2="/Fo/$BUILDDIR2/";
  out2="/out:$outfile2";
  "$cl" /nologo /EHsc "$fo2" "$@" /link "$out2"; wine "$outfile2"; rm "$outfile2";
}

# hello world
compile_and_exec "test/main.c"
compile_and_exec "test\\main.c"


compile_and_exec "test/main.cpp";
compile_and_exec "test/winmain.cpp";
compile_and_exec "/DCICCIA" "test/macro.c";

# file system
compile_and_exec "/std:c++17" "test/filesystem.cpp";

#
#...

# i/o
compile "test/io.cpp"; printf '1 2 3 4 stop a\n' | wine "$outfile"; rm "$outfile";

# threading
compile_and_exec "test/thread.cpp";
compile_and_exec "test/thread_win.cpp";

# gui
compile "test/messagebox.cpp" "user32.lib"; timeout --preserve-status --signal=QUIT 1 wine "$outfile"; rm "$outfile";

# strange param combination with unix and windows paths

#  cl + link (separte step), could redo all previous samples
"$cl" /EHsc "/Fo$BUILDDIR/main.obj" -c test/main.cpp && "$link" "$out" "$BUILDDIR/main.obj"; wine "$outfile"; rm "$outfile";

# link library
#"$cl" "$fo" -c lib/main.cpp "$out";

"$cl" /EHsc "$fo" -c "test/lib/lib.cpp"
"$lib" "/out:$BUILDDIR/lib.lib" "$BUILDDIR/lib.obj"
"$cl" /EHsc "$fo" -c "test/lib/main.cpp" /link "/out:$BUILDDIR/main.obj"
"$cl" /EHsc "$fo" "$BUILDDIR/main.obj" "$BUILDDIR/lib.obj" /link "$out"
wine "$outfile"; rm "$outfile";

# example with MFC/ATL

# shared library,unable to start in separate wine prefix
rm -rf "$BUILDDIR/mfc/shared" || true;
mkdir -p "$BUILDDIR/mfc/shared";

mfc_macros="/DWIN32_LEAN_AND_MEAN /DNOMINMAX /DSTRICT /DNTDDI_VERSION=NTDDI_VISTA /D_WIN32_WINNT=_WIN32_WINNT_VISTA /DWINVER=_WIN32_WINNT_VISTA /D_UNICODE /DUNICODE /D_ATL_CSTRING_EXPLICIT_CONSTRUCTORS /D_ATL_ALL_WARNINGS /D_SECURE_ATL=1 /D_UNICODE /DUNICODE";

"$cl" /c /Zi /EHsc /MD /D_AFXDLL $mfc_macros "/Fo$BUILDDIR/mfc/shared/" "/Fd$BUILDDIR/mfc/shared/" "test/mfc/main.cpp" "test/mfc/mydialog.cpp"

"$rc" /D_AFXDLL $mfc_macros /l 0x0409 /fo"$BUILDDIR/mfc/shared/manifest.res" "test/mfc/resource.rc"

#"$mt" /verbose /out:"$BUILDDIR/mfc/shared/mfc.exe.embed.manifest" /nologo "$BUILDDIR/mfc/shared/manifest.res"

"$link" /OUT:"$BUILDDIR/mfc/shared/mfc.exe" /MANIFEST /MACHINE:X64 /SUBSYSTEM:WINDOWS "/ENTRY:wWinMainCRTStartup" /MANIFESTUAC:"level='asInvoker' uiAccess='false'" "$BUILDDIR/mfc/shared/manifest.res" "$BUILDDIR/mfc/shared/main.obj" "$BUILDDIR/mfc/shared/mydialog.obj"

# static library,unable to start in separate wine prefix
rm -rf "$BUILDDIR/mfc/static" || true;
mkdir -p "$BUILDDIR/mfc/static";
"$cl" /c /Zi $mfc_macros /EHsc /MT "/Fo$BUILDDIR/mfc/static/" "/Fd$BUILDDIR/mfc/static/" "test/mfc/main.cpp" "test/mfc/mydialog.cpp"

"$rc" $mfc_macros /l 0x0409 /fo"$BUILDDIR/mfc/static/manifest.res" "test/mfc/resource.rc"

#"$mt" /verbose /out:"$BUILDDIR/mfc/static/mfc.exe.embed.manifest" /nologo "$BUILDDIR/mfc/shared/manifest.res"

"$link" "/OUT:$BUILDDIR/mfc/static/mfc.exe" /MANIFEST /MACHINE:X64 /SUBSYSTEM:WINDOWS "/ENTRY:wWinMainCRTStartup" /MANIFESTUAC:"level='asInvoker' uiAccess='false'" "$BUILDDIR/mfc/static/manifest.res" "$BUILDDIR/mfc/static/main.obj" "$BUILDDIR/mfc/static/mydialog.obj"


timeout --preserve-status --signal=QUIT 2 wine "$BUILDDIR/mfc/static/mfc.exe";
# example with other libraries....


# use cmake internal testsuite :-)
cmake -B "$BUILDDIR/cmake-build" -S test \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_VERSION=1 \
  -DCMAKE_C_COMPILER="$cl" \
  -DCMAKE_CXX_COMPILER="$cl" \
  -DCMAKE_LINKER="$link" \
  -DCMAKE_RC_COMPILER="$rc" \
  -DCMAKE_MT_COMPILER="$mt" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
  --debug-trycompile

# setting makeflags to 1, since with parallel builds cl.exe chokes on mfc target with fatal error C1041, and setting /FS does not help
MAKEFLAGS=-j1 cmake --build "$BUILDDIR/cmake-build" -- all;
