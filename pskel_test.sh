#!/bin/sh -e

case "${1}" in
  "") ;;
  "test") TEST_EXTENSION=1;;
  "debug") TEST_EXTENSION_DEBUG=1;;
  "valgrind") TEST_EXTENSION_VALGRIND=1;;
  "msan") TEST_EXTENSION_MSAN=1;;
  "asan") TEST_EXTENSION_ASAN=1;;
  "ubsan") TEST_EXTENSION_UBSAN=1;;
  *) printf "Pskel Test\nUsage:\n\t\t%s\t\t: %s\n\t\t%s\t\t: %s\n\t\t%s\t: %s\n\t\t%s\t\t: %s\n\t\t%s\t\t: %s\n\t\t%s\t\t: %s\n" "test" "Test extension with pre-installed PHP binary. [bin: $(which "php")]" "debug" "Test extension with Debug Build (GCC) binary. [bin: $(which "debug-php")]" "valgrind" "Test extension with GCC binary with Valgrind. [bin: $(which "gcc-valgrind-php")]" "msan" "Test extension with Clang binary with MemorySanitizer. [bin: $(which "clang-msan-php")]" "asan" "Test extension with Clang binary with AddressSanitizer. [bin: $(which "clang-asan-php")]" "ubsan" "Test extension with Clang binary with UndefinedBehaviorSanitizer. [bin: $(which "clang-ubsan-php")]"; exit 0;;
esac

if test -f "/ext/.gitkeep" && test $(cat "/ext/.gitkeep") = "pskel_uninitialized"; then
  echo "[Pskel Test] Uninitialized project detected, initialize default skeleton"
  rm -rf "/ext"
  /usr/local/bin/php "/usr/src/php/ext/ext_skel.php" --ext "ext" --dir "/"
fi

PSKEL_WORKDIR="/ext"

if test -d "/work/ext"; then
  echo "[Pskel Test] DevContainer workspace detected, use \"/work/ext\"."
  PSKEL_WORKDIR="/work/ext"
fi

echo "[Pskel Test] BEGIN TEST"

if test "${TEST_EXTENSION}" != ""; then
  cd "${PSKEL_WORKDIR}"
  phpize
  ./configure --with-php-config="$(which php-config)"
  make clean
  make -j"$(nproc)"
  TEST_PHP_ARGS="--show-diff -q" make test
else
  echo "[Pskel Test] skip: TEST_EXTENSION is not set"
fi

if test "${TEST_EXTENSION_DEBUG}" != ""; then
  cd "${PSKEL_WORKDIR}"
  debug-phpize
  ./configure --with-php-config="$(which debug-php-config)"
  make clean
  make -j"$(nproc)"
  TEST_PHP_ARGS="--show-diff -q" make test
else
  echo "[Pskel Test] skip: TEST_EXTENSION_DEBUG is not set"
fi

if test "${TEST_EXTENSION_VALGRIND}" != ""; then
  if type "gcc-valgrind-php" > /dev/null 2>&1; then
    cd "${PSKEL_WORKDIR}"
    gcc-valgrind-phpize
    ./configure --with-php-config="$(which gcc-valgrind-php-config)"
    make clean
    make -j"$(nproc)"
    TEST_PHP_ARGS="--show-diff -q -m" make test
  else
    echo "[Pskel Test] missing gcc-valgrind-php"
    exit 1
  fi
else
  echo "[Pskel Test] skip: TEST_EXTENSION_VALGRIND is not set"
fi

if test "${TEST_EXTENSION_MSAN}" != ""; then
  if type "clang-msan-php" > /dev/null 2>&1; then
    cd "${PSKEL_WORKDIR}"
    clang-msan-phpize
    CC="clang" CXX="clang++" CFLAGS="-fsanitize=memory -DZEND_TRACK_ARENA_ALLOC" CPPFLAGS="-fsanitize=memory -DZEND_TRACK_ARENA_ALLOC ${CPPFLAGS}" LDFLAGS="-fsanitize=memory" ./configure --with-php-config="$(which clang-msan-php-config)"
    make clean
    CFLAGS="-fsanitize=memory -DZEND_TRACK_ARENA_ALLOC ${CFLAGS}" CPPFLAGS="-fsanitize=memory -DZEND_TRACK_ARENA_ALLOC ${CPPFLAGS}" LDFLAGS="-fsanitize=memory" make -j"$(nproc)"
    TEST_PHP_ARGS="--show-diff -q --msan" make test
  else
    echo "[Pskel Test] missing clang-msan-php"
    exit 1
  fi
else
  echo "[Pskel Test] skip: TEST_EXTENSION_MSAN is not set"
fi

if test "${TEST_EXTENSION_ASAN}" != ""; then
  if type "clang-asan-php" > /dev/null 2>&1; then
    cd "${PSKEL_WORKDIR}"
    clang-asan-phpize
    CC="clang" CXX="clang++" CFLAGS="-fsanitize=address -DZEND_TRACK_ARENA_ALLOC" CPPFLAGS="-fsanitize=address -DZEND_TRACK_ARENA_ALLOC ${CPPFLAGS}" LDFLAGS="-fsanitize=address" ./configure --with-php-config="$(which clang-asan-php-config)"
    make clean
    CFLAGS="-fsanitize=address -DZEND_TRACK_ARENA_ALLOC ${CFLAGS}" CPPFLAGS="-fsanitize=address -DZEND_TRACK_ARENA_ALLOC ${CPPFLAGS}" LDFLAGS="-fsanitize=address" make -j"$(nproc)"
    TEST_PHP_ARGS="--show-diff -q --asan" make test
  else
    echo "[Pskel Test] missing clang-asan-php"
    exit 1
  fi
else
  echo "[Pskel Test] skip: TEST_EXTENSION_ASAN is not set"
fi

if test "${TEST_EXTENSION_UBSAN}" != ""; then
  if type "clang-ubsan-php" > /dev/null 2>&1; then
    cd "${PSKEL_WORKDIR}"
    clang-ubsan-phpize
    CC="clang" CXX="clang++" CFLAGS="-fsanitize=undefined -DZEND_TRACK_ARENA_ALLOC" CPPFLAGS="-fsanitize=undefined -DZEND_TRACK_ARENA_ALLOC ${CPPFLAGS}" LDFLAGS="-fsanitize=undefined" ./configure --with-php-config="$(which clang-ubsan-php-config)"
    make clean
    CFLAGS="-fsanitize=undefined -DZEND_TRACK_ARENA_ALLOC ${CFLAGS}" CPPFLAGS="-fsanitize=undefined -DZEND_TRACK_ARENA_ALLOC ${CPPFLAGS}" LDFLAGS="-fsanitize=undefined" make -j"$(nproc)"
    TEST_PHP_ARGS="--show-diff -q" make test
  else
    echo "[Pskel Test] missing clang-ubsan-php"
    exit 1
  fi
else
  echo "[Pskel Test] skip: TEST_EXTENSION_UBSAN is not set"
fi

echo "[Pskel Test] END TEST"
exit 0
