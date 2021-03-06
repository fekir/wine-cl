#!/bin/sh

set -o errexit
set -o nounset

help(){
  printf '%s\n\n' "${0##*/}";

  printf '\t--help prints this message\n';
  printf '\t--cl\n'
  printf '\t--link\n'
  printf '\t--lib\n'
  printf '\t--rc\n'
  printf '\t--mt\n'
  printf '\t--bld\n'
}

check_value() {
  if [ "$1" -lt 2 ]; then :;
    printf 'Missing value for %s\n\n' "$2"; help; exit 1;
  fi
}

cmake_test_i(){
  gen="$1"; shift;
  dir="$1"; shift;
  cl="$1"; shift;
  link="$1"; shift;
  rc="$1"; shift;
  mt="$1"; shift;
  build_type="$1"; shift;
  source_dir="${1:-test}"; #shift 2>/dev/null || true;
  cmake -G"$gen" -B "$dir.$build_type" -DCMAKE_BUILD_TYPE="$build_type" -S "$source_dir" \
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
    --debug-trycompile --no-warn-unused-cli
  cmake --build "$dir.$build_type" -- all;
}
cmake_test(){
  cmake_test_i "$@" "Release"
  cmake_test_i "$@" "Debug"
  cmake_test_i "$@" "RelWithDebInfo"
}

# when using XDG_RUNTIME_DIR, wine hangs
BASE_BUILD_DIR=${TMPDIR:-${TMP:-${TEMP:-/tmp}}}
TIMEOUT=3

main() {
  [ $# -eq 0 ] && set -- "$@" '?';

  while test "$#" -gt 0; do :;
    key="$1";
    case "$key" in
      -h|--help|h|help|\?)
        help; exit 0;
        ;;
      --cl)
        check_value "$#" "$key"; cl="$2"; shift;
        ;;
      --link)
        check_value "$#" "$key"; link="$2"; shift;
        ;;
      --lib)
        check_value "$#" "$key"; lib="$2"; shift;
        ;;
      --rc)
        check_value "$#" "$key"; rc="$2"; shift;
        ;;
      --mt)
        check_value "$#" "$key"; mt="$2"; shift;
        ;;
      --bld)
        check_value "$#" "$key"; BUILDDIR="$2"; shift;
        ;;
      *)
        { printf 'Unrecognized value: %s\n\n' "$key"; help; } >&2;
        exit 1;
        ;;
    esac
    shift;
  done
  if [ ! -n "${BLD+x}" ]; then :;
    BUILDDIR="$(mktemp -p "$BASE_BUILD_DIR" -d test-msvc.XXXXXX.d)";
    trap 'wineserver --kill; echo "Error occured, check result in $BUILDDIR"' INT QUIT EXIT;
  else :;
    trap 'wineserver --kill' INT QUIT EXIT;
  fi

  outfile="$BUILDDIR/a.out"
  fo="/Fo/$BUILDDIR/"
  out="/out:$outfile"

  # avoid changing user home
  WINEPREFIX="$(mktemp -p "$BUILDDIR" -d wine.XXXXXX.d)";
  export WINEPREFIX;
  export WINEDLLOVERRIDES="mscoree,mshtml="; # avoid unnecessary bloat
  env -u DISPLAY WINEDEBUG=-all wine wineboot;

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

  # i/o
  compile "test/io.cpp"; printf '1 2 3 4 stop a\n' | wine "$outfile"; rm "$outfile";

  # threading
  compile_and_exec "test/thread.cpp";
  compile_and_exec "test/thread_win.cpp";

  # gui
  compile "test/messagebox.cpp" "user32.lib"; timeout --preserve-status --signal=QUIT "$TIMEOUT" wine "$outfile" || echo "timeout failed (mostly false positive)"; rm "$outfile";

  # strange param combination with unix and windows paths

  #  cl + link (separate step), could redo all previous samples
  "$cl" /EHsc "/Fo$BUILDDIR/main.obj" -c test/main.cpp && "$link" "$out" "$BUILDDIR/main.obj"; wine "$outfile"; rm "$outfile";
  
  # debug params seems to cause issues:
  "$cl" /EHsc "/Fo$BUILDDIR/main.obj" -c test/main.cpp && "$link" /debug:NONE "$out" "$BUILDDIR/main.obj"; wine "$outfile"; rm "$outfile";
  "$cl" /EHsc "/Fo$BUILDDIR/main.obj" -c test/main.cpp && "$link" /debug:FASTLINK "$out" "$BUILDDIR/main.obj"; wine "$outfile"; rm "$outfile";
  "$cl" /EHsc "/Fo$BUILDDIR/main.obj" -c test/main.cpp && "$link" /debug "$out" "$BUILDDIR/main.obj"; wine "$outfile"; rm "$outfile";
  "$cl" /EHsc "/Fo$BUILDDIR/main.obj" -c test/main.cpp && "$link" /debug:FULL "$out" "$BUILDDIR/main.obj"; wine "$outfile"; rm "$outfile";

  # link library
  #"$cl" "$fo" -c lib/main.cpp "$out";

  "$cl" /EHsc "$fo" -c "test/lib/lib.cpp"
  "$lib" "/out:$BUILDDIR/lib.lib" "$BUILDDIR/lib.obj"
  "$cl" /EHsc "$fo" -c "test/lib/main.cpp" /link "/out:$BUILDDIR/main.obj"
  "$cl" /EHsc "$fo" "$BUILDDIR/main.obj" "$BUILDDIR/lib.obj" /link "$out"
  wine "$outfile"; rm "$outfile";

  # example with MFC/ATL

  # shared library, unable to start in separate wine prefix, do not execute
  rm -rf "$BUILDDIR/mfc/shared" || true;
  mkdir -p "$BUILDDIR/mfc/shared";

  mfc_macros="/DWIN32_LEAN_AND_MEAN /DNOMINMAX /DSTRICT /DNTDDI_VERSION=NTDDI_VISTA /D_WIN32_WINNT=_WIN32_WINNT_VISTA /DWINVER=_WIN32_WINNT_VISTA /D_UNICODE /DUNICODE /D_ATL_CSTRING_EXPLICIT_CONSTRUCTORS /D_ATL_ALL_WARNINGS /D_SECURE_ATL=1";

  "$cl" /c /EHsc /MD /D_AFXDLL $mfc_macros "/Fo$BUILDDIR/mfc/shared/" "/Fd$BUILDDIR/mfc/shared/" "test/mfc/main.cpp" "test/mfc/mydialog.cpp"

  "$rc" /D_AFXDLL $mfc_macros /l 0x0409 /fo"$BUILDDIR/mfc/shared/manifest.res" "test/mfc/resource.rc"

  #"$mt" /verbose /out:"$BUILDDIR/mfc/shared/mfc.exe.embed.manifest" /nologo "$BUILDDIR/mfc/shared/manifest.res"

  "$link" /OUT:"$BUILDDIR/mfc/shared/mfc.exe" /MANIFEST /SUBSYSTEM:WINDOWS "/ENTRY:wWinMainCRTStartup" /MANIFESTUAC:"level='asInvoker' uiAccess='false'" "$BUILDDIR/mfc/shared/manifest.res" "$BUILDDIR/mfc/shared/main.obj" "$BUILDDIR/mfc/shared/mydialog.obj"

  # static library
  rm -rf "$BUILDDIR/mfc/static" || true;
  mkdir -p "$BUILDDIR/mfc/static";
  "$cl" /c $mfc_macros /EHsc /MT "/Fo$BUILDDIR/mfc/static/" "/Fd$BUILDDIR/mfc/static/" "test/mfc/main.cpp" "test/mfc/mydialog.cpp"

  "$rc" $mfc_macros /l 0x0409 /fo"$BUILDDIR/mfc/static/manifest.res" "test/mfc/resource.rc"

  #"$mt" /verbose /out:"$BUILDDIR/mfc/static/mfc.exe.embed.manifest" /nologo "$BUILDDIR/mfc/shared/manifest.res"

  "$link" "/OUT:$BUILDDIR/mfc/static/mfc.exe" /MANIFEST /SUBSYSTEM:WINDOWS "/ENTRY:wWinMainCRTStartup" /MANIFESTUAC:"level='asInvoker' uiAccess='false'" "$BUILDDIR/mfc/static/manifest.res" "$BUILDDIR/mfc/static/main.obj" "$BUILDDIR/mfc/static/mydialog.obj"

  timeout --preserve-status --signal=QUIT "$TIMEOUT" wine "$BUILDDIR/mfc/static/mfc.exe";
  # example with other libraries....

  # use cmake internal testsuite :-)
  cmake_test "Unix Makefiles" "$BUILDDIR/cmake-make" "$cl" "$link" "$rc" "$mt";

  if ! command -v ninja > /dev/null 2>&1; then :;
    printf 'Skip ninja test suite, as ninja does not seem to be avaiable\n';
  else
    cmake_test "Ninja" "$BUILDDIR/cmake-ninja" "$cl" "$link" "$rc" "$mt";
  fi

  # everything ended well, remove output folder instead of displaying help msg
  trap 'wineserver --kill; rm -rf "$BUILDDIR"' INT QUIT EXIT;
}

main "$@";
