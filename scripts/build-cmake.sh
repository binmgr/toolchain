#!/bin/bash
# =============================================================================
# CMake Cross-Compilation Template
# =============================================================================
# Usage: ./scripts/build-cmake.sh [target] [source-dir] [build-dir]
#
# Targets: linux-amd64, linux-arm64, linux-armv7, linux-riscv64,
#          windows-amd64, windows-arm64, darwin-amd64, darwin-arm64,
#          freebsd-amd64, freebsd-arm64, wasi
#
# Example:
#   docker run --rm -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest \
#       ./scripts/build-cmake.sh linux-arm64 . build-arm64
# =============================================================================

set -e

TARGET="${1:-linux-amd64}"
SOURCE_DIR="${2:-.}"
BUILD_DIR="${3:-build-$TARGET}"

echo "Configuring CMake for target: $TARGET"
echo "Source directory: $SOURCE_DIR"
echo "Build directory: $BUILD_DIR"

# Setup target environment
source /usr/local/bin/entrypoint.sh --setup "$TARGET" 2>/dev/null || true

# CMake toolchain configuration
CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=OFF
)

# Target-specific configuration
case "$TARGET" in
    linux-amd64)
        CMAKE_ARGS+=(
            -DCMAKE_C_COMPILER=gcc
            -DCMAKE_CXX_COMPILER=g++
            -DCMAKE_EXE_LINKER_FLAGS="-static"
        )
        ;;
    linux-arm64)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=Linux
            -DCMAKE_SYSTEM_PROCESSOR=aarch64
            -DCMAKE_C_COMPILER=aarch64-linux-gcc
            -DCMAKE_CXX_COMPILER=aarch64-linux-g++
            -DCMAKE_FIND_ROOT_PATH=/opt/aarch64-linux-musl/aarch64-buildroot-linux-musl/sysroot
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
            -DCMAKE_EXE_LINKER_FLAGS="-static"
        )
        ;;
    linux-armv7)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=Linux
            -DCMAKE_SYSTEM_PROCESSOR=arm
            -DCMAKE_C_COMPILER=armv7-linux-gcc
            -DCMAKE_CXX_COMPILER=armv7-linux-g++
            -DCMAKE_FIND_ROOT_PATH=/opt/armv7-linux-musl/arm-buildroot-linux-musleabihf/sysroot
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
            -DCMAKE_EXE_LINKER_FLAGS="-static"
        )
        ;;
    linux-riscv64)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=Linux
            -DCMAKE_SYSTEM_PROCESSOR=riscv64
            -DCMAKE_C_COMPILER=riscv64-linux-gcc
            -DCMAKE_CXX_COMPILER=riscv64-linux-g++
            -DCMAKE_FIND_ROOT_PATH=/opt/riscv64-linux-musl/riscv64-buildroot-linux-musl/sysroot
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
            -DCMAKE_EXE_LINKER_FLAGS="-static"
        )
        ;;
    windows-amd64)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=Windows
            -DCMAKE_SYSTEM_PROCESSOR=AMD64
            -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang
            -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++
            -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres
            -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/x86_64-w64-mingw32
            -DCMAKE_EXE_LINKER_FLAGS="-static"
        )
        ;;
    windows-arm64)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=Windows
            -DCMAKE_SYSTEM_PROCESSOR=ARM64
            -DCMAKE_C_COMPILER=aarch64-w64-mingw32-clang
            -DCMAKE_CXX_COMPILER=aarch64-w64-mingw32-clang++
            -DCMAKE_RC_COMPILER=aarch64-w64-mingw32-windres
            -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/aarch64-w64-mingw32
            -DCMAKE_EXE_LINKER_FLAGS="-static"
        )
        ;;
    darwin-amd64)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=Darwin
            -DCMAKE_SYSTEM_PROCESSOR=x86_64
            -DCMAKE_C_COMPILER=x86_64-apple-darwin23-clang
            -DCMAKE_CXX_COMPILER=x86_64-apple-darwin23-clang++
            -DCMAKE_OSX_SYSROOT=/opt/osxcross/target/SDK/MacOSX14.0.sdk
        )
        ;;
    darwin-arm64)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=Darwin
            -DCMAKE_SYSTEM_PROCESSOR=aarch64
            -DCMAKE_C_COMPILER=aarch64-apple-darwin23-clang
            -DCMAKE_CXX_COMPILER=aarch64-apple-darwin23-clang++
            -DCMAKE_OSX_SYSROOT=/opt/osxcross/target/SDK/MacOSX14.0.sdk
        )
        ;;
    freebsd-amd64)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=FreeBSD
            -DCMAKE_SYSTEM_PROCESSOR=x86_64
            -DCMAKE_C_COMPILER=x86_64-freebsd-clang
            -DCMAKE_CXX_COMPILER=x86_64-freebsd-clang++
            -DCMAKE_SYSROOT=/opt/bsd-cross/freebsd
            -DCMAKE_EXE_LINKER_FLAGS="-static"
        )
        ;;
    wasi)
        CMAKE_ARGS+=(
            -DCMAKE_SYSTEM_NAME=WASI
            -DCMAKE_SYSTEM_PROCESSOR=wasm32
            -DCMAKE_C_COMPILER=/opt/wasi-sdk/bin/clang
            -DCMAKE_CXX_COMPILER=/opt/wasi-sdk/bin/clang++
            -DCMAKE_SYSROOT=/opt/wasi-sdk/share/wasi-sysroot
            -DCMAKE_C_COMPILER_TARGET=wasm32-wasi
            -DCMAKE_CXX_COMPILER_TARGET=wasm32-wasi
        )
        ;;
    *)
        echo "error: Unknown target: $TARGET"
        exit 1
        ;;
esac

# Create build directory
mkdir -p "$BUILD_DIR"

# Configure
echo ""
echo "Running CMake configure..."
cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" "${CMAKE_ARGS[@]}"

# Build
echo ""
echo "Running CMake build..."
cmake --build "$BUILD_DIR" --parallel "$(nproc)"

echo ""
echo "Build complete!"
echo "Output directory: $BUILD_DIR"
