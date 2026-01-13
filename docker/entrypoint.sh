#!/bin/bash
# binmgr/toolchain entrypoint script
# Configures the build environment for cross-compilation and static binary builds

set -e

# Version information
TOOLCHAIN_VERSION="2601"
IMAGE_NAME="binmgr/toolchain"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

print_success() {
    echo -e "${GREEN}✓${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

print_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$*${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Show help
show_help() {
    cat <<EOF
${CYAN}binmgr/toolchain${NC} - Universal cross-compilation toolchain for static binaries

${YELLOW}USAGE:${NC}
    docker run [OPTIONS] ghcr.io/${IMAGE_NAME}:latest [COMMAND] [ARGS...]

${YELLOW}SPECIAL COMMANDS:${NC}
    --help              Show this help message
    --version           Show toolchain version and capabilities
    --info              Show detailed toolchain information
    --list-targets      List all available compilation targets
    --setup TARGET      Configure environment for TARGET compilation
    --shell             Start an interactive shell with default environment

${YELLOW}ENVIRONMENT VARIABLES:${NC}
    ${GREEN}Build Configuration:${NC}
    TARGET              Cross-compilation target (e.g., linux-arm64, windows-amd64)
    CC                  C compiler to use
    CXX                 C++ compiler to use
    AR                  Archiver to use
    RANLIB              ranlib to use
    STRIP               Strip utility to use

    ${GREEN}Build Optimization:${NC}
    USE_CCACHE          Enable ccache (default: 1)
    CCACHE_DIR          ccache directory (default: /workspace/.ccache)
    PARALLEL_JOBS       Number of parallel build jobs (default: auto-detect)

    ${GREEN}Static Linking:${NC}
    ENABLE_STATIC       Force static linking (default: 1)
    LDFLAGS             Linker flags (auto-configured for static builds)

    ${GREEN}Package Config:${NC}
    PKG_CONFIG_PATH     pkg-config search path (auto-configured per target)
    PKG_CONFIG          pkg-config binary (target-specific wrapper)

${YELLOW}AVAILABLE TARGETS:${NC}
    ${GREEN}Linux:${NC}          linux-amd64, linux-arm64
    ${GREEN}Windows:${NC}        windows-amd64, windows-arm64
    ${GREEN}macOS:${NC}          darwin-amd64, darwin-arm64
    ${GREEN}FreeBSD:${NC}        freebsd-amd64, freebsd-arm64
    ${GREEN}OpenBSD:${NC}        openbsd-amd64, openbsd-arm64
    ${GREEN}NetBSD:${NC}         netbsd-amd64, netbsd-arm64
    ${GREEN}Android:${NC}        android-arm64, android-armv7, android-x86_64, android-x86
    ${GREEN}WebAssembly:${NC}    wasm32, wasm64

${YELLOW}EXAMPLES:${NC}
    # Show toolchain information
    docker run --rm ghcr.io/${IMAGE_NAME}:latest --info

    # Build for Linux ARM64
    docker run --rm -v \$(pwd):/workspace -e TARGET=linux-arm64 \\
        ghcr.io/${IMAGE_NAME}:latest make

    # Interactive shell for Windows AMD64 development
    docker run --rm -it -v \$(pwd):/workspace -e TARGET=windows-amd64 \\
        ghcr.io/${IMAGE_NAME}:latest --shell

    # Setup environment and run configure
    docker run --rm -v \$(pwd):/workspace -e TARGET=freebsd-arm64 \\
        ghcr.io/${IMAGE_NAME}:latest ./configure --enable-static

    # Build with custom compiler flags
    docker run --rm -v \$(pwd):/workspace \\
        -e CC=gcc -e CFLAGS="-O3 -march=native" \\
        ghcr.io/${IMAGE_NAME}:latest make

${YELLOW}MORE INFORMATION:${NC}
    Repository: https://github.com/binmgr/toolchain
    Issues:     https://github.com/binmgr/toolchain/issues
    Docs:       https://github.com/binmgr/toolchain/blob/main/README.md

EOF
}

# Show version and capabilities
show_version() {
    print_header "binmgr/toolchain v${TOOLCHAIN_VERSION}"
    echo ""
    toolchain-info
}

# List all available targets
list_targets() {
    print_header "Available Compilation Targets"
    echo ""
    echo -e "${GREEN}Linux (musl):${NC}"
    echo "  • linux-amd64        Native x86_64 with musl libc"
    echo "  • linux-arm64        ARM64/AArch64 with musl libc"
    echo ""
    echo -e "${GREEN}Windows (MinGW):${NC}"
    echo "  • windows-amd64      x86_64 Windows (LLVM MinGW)"
    echo "  • windows-arm64      ARM64 Windows (LLVM MinGW)"
    echo ""
    echo -e "${GREEN}macOS (OSXCross):${NC}"
    echo "  • darwin-amd64       x86_64 macOS (Darwin 23)"
    echo "  • darwin-arm64       ARM64 Apple Silicon (Darwin 23)"
    echo ""
    echo -e "${GREEN}FreeBSD:${NC}"
    echo "  • freebsd-amd64      x86_64 FreeBSD 14"
    echo "  • freebsd-arm64      ARM64 FreeBSD 14"
    echo ""
    echo -e "${GREEN}OpenBSD:${NC}"
    echo "  • openbsd-amd64      x86_64 OpenBSD"
    echo "  • openbsd-arm64      ARM64 OpenBSD"
    echo ""
    echo -e "${GREEN}NetBSD:${NC}"
    echo "  • netbsd-amd64       x86_64 NetBSD"
    echo "  • netbsd-arm64       ARM64 NetBSD"
    echo ""
    echo -e "${GREEN}Android (NDK r27c, API 24+):${NC}"
    echo "  • android-arm64      ARM64-v8a (aarch64)"
    echo "  • android-armv7      ARMv7-a (32-bit ARM)"
    echo "  • android-x86_64     x86_64 (Intel/AMD 64-bit)"
    echo "  • android-x86        x86 (Intel/AMD 32-bit)"
    echo ""
    echo -e "${GREEN}WebAssembly:${NC}"
    echo "  • wasm32             32-bit WebAssembly (Emscripten)"
    echo "  • wasm64             64-bit WebAssembly (experimental)"
    echo ""
}

# Configure environment for specific target
setup_target() {
    local target="$1"

    if [ -z "$target" ]; then
        print_error "No target specified"
        echo "Usage: $0 --setup TARGET"
        echo "Run '$0 --list-targets' to see available targets"
        return 1
    fi

    print_info "Configuring environment for target: ${GREEN}${target}${NC}"

    # Export target
    export TARGET="$target"
    export CROSS_COMPILE=1

    # Common static linking flags
    export ENABLE_STATIC=1

    case "$target" in
        linux-amd64)
            export CC=gcc
            export CXX=g++
            export AR=ar
            export RANLIB=ranlib
            export STRIP=strip
            export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/lib/x86_64-linux-musl/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        linux-arm64)
            export CC=aarch64-linux-gcc
            export CXX=aarch64-linux-g++
            export AR=aarch64-linux-ar
            export RANLIB=aarch64-linux-ranlib
            export STRIP=aarch64-linux-strip
            export PKG_CONFIG_PATH="/opt/aarch64-linux-musl/aarch64-buildroot-linux-musl/sysroot/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        windows-amd64)
            export CC=x86_64-w64-mingw32-clang
            export CXX=x86_64-w64-mingw32-clang++
            export AR=x86_64-w64-mingw32-ar
            export RANLIB=x86_64-w64-mingw32-ranlib
            export STRIP=x86_64-w64-mingw32-strip
            export PKG_CONFIG_PATH="/opt/llvm-mingw/x86_64-w64-mingw32/lib/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        windows-arm64)
            export CC=aarch64-w64-mingw32-clang
            export CXX=aarch64-w64-mingw32-clang++
            export AR=aarch64-w64-mingw32-ar
            export RANLIB=aarch64-w64-mingw32-ranlib
            export STRIP=aarch64-w64-mingw32-strip
            export PKG_CONFIG_PATH="/opt/llvm-mingw/aarch64-w64-mingw32/lib/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        darwin-amd64)
            export CC=x86_64-apple-darwin23-clang
            export CXX=x86_64-apple-darwin23-clang++
            export AR=x86_64-apple-darwin23-ar
            export RANLIB=x86_64-apple-darwin23-ranlib
            export STRIP=x86_64-apple-darwin23-strip
            export PKG_CONFIG_PATH="/opt/osxcross/target/SDK/MacOSX14.0.sdk/usr/lib/pkgconfig"
            ;;
        darwin-arm64)
            export CC=aarch64-apple-darwin23-clang
            export CXX=aarch64-apple-darwin23-clang++
            export AR=aarch64-apple-darwin23-ar
            export RANLIB=aarch64-apple-darwin23-ranlib
            export STRIP=aarch64-apple-darwin23-strip
            export PKG_CONFIG_PATH="/opt/osxcross/target/SDK/MacOSX14.0.sdk/usr/lib/pkgconfig"
            ;;
        freebsd-amd64)
            export CC=x86_64-freebsd-clang
            export CXX=x86_64-freebsd-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export PKG_CONFIG_PATH="/opt/bsd-cross/freebsd/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            ;;
        freebsd-arm64)
            export CC=aarch64-freebsd-clang
            export CXX=aarch64-freebsd-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export PKG_CONFIG_PATH="/opt/bsd-cross/freebsd/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            ;;
        openbsd-amd64)
            export CC=x86_64-openbsd-clang
            export CXX=x86_64-openbsd-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export PKG_CONFIG_PATH="/opt/bsd-cross/openbsd/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            ;;
        openbsd-arm64)
            export CC=aarch64-openbsd-clang
            export CXX=aarch64-openbsd-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export PKG_CONFIG_PATH="/opt/bsd-cross/openbsd/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            ;;
        netbsd-amd64)
            export CC=x86_64-netbsd-clang
            export CXX=x86_64-netbsd-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export PKG_CONFIG_PATH="/opt/bsd-cross/netbsd/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            ;;
        netbsd-arm64)
            export CC=aarch64-netbsd-clang
            export CXX=aarch64-netbsd-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export PKG_CONFIG_PATH="/opt/bsd-cross/netbsd/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            ;;
        android-arm64)
            export CC=aarch64-linux-android24-clang
            export CXX=aarch64-linux-android24-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            local ndk_host=$(uname -m | sed 's/x86_64/linux-x86_64/;s/aarch64/linux-x86_64/')
            export PKG_CONFIG_PATH="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${ndk_host}/sysroot/usr/lib/aarch64-linux-android/pkgconfig"
            ;;
        android-armv7)
            export CC=armv7a-linux-androideabi24-clang
            export CXX=armv7a-linux-androideabi24-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            local ndk_host=$(uname -m | sed 's/x86_64/linux-x86_64/;s/aarch64/linux-x86_64/')
            export PKG_CONFIG_PATH="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${ndk_host}/sysroot/usr/lib/arm-linux-androideabi/pkgconfig"
            ;;
        android-x86_64)
            export CC=x86_64-linux-android24-clang
            export CXX=x86_64-linux-android24-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            local ndk_host=$(uname -m | sed 's/x86_64/linux-x86_64/;s/aarch64/linux-x86_64/')
            export PKG_CONFIG_PATH="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${ndk_host}/sysroot/usr/lib/x86_64-linux-android/pkgconfig"
            ;;
        android-x86)
            export CC=i686-linux-android24-clang
            export CXX=i686-linux-android24-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            local ndk_host=$(uname -m | sed 's/x86_64/linux-x86_64/;s/aarch64/linux-x86_64/')
            export PKG_CONFIG_PATH="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${ndk_host}/sysroot/usr/lib/i686-linux-android/pkgconfig"
            ;;
        wasm32|wasm64)
            export CC=emcc
            export CXX=em++
            export AR=emar
            export RANLIB=emranlib
            # Emscripten has its own pkg-config handling
            ;;
        *)
            print_error "Unknown target: $target"
            echo "Run '$0 --list-targets' to see available targets"
            return 1
            ;;
    esac

    print_success "Environment configured for ${GREEN}${target}${NC}"
    echo ""
    echo "Compiler settings:"
    echo "  CC:      $CC"
    echo "  CXX:     $CXX"
    echo "  AR:      $AR"
    echo "  RANLIB:  $RANLIB"
    if [ -n "$PKG_CONFIG_PATH" ]; then
        echo "  PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
    fi
    if [ -n "$LDFLAGS" ]; then
        echo "  LDFLAGS: $LDFLAGS"
    fi
    echo ""
}

# Initialize default environment
init_environment() {
    # Detect host architecture and add Android NDK to PATH
    local host_arch=$(uname -m)
    if [ "$host_arch" = "x86_64" ]; then
        export PATH="/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
    elif [ "$host_arch" = "aarch64" ]; then
        # Check which prebuilt directory exists
        if [ -d "/opt/android-ndk/toolchains/llvm/prebuilt/linux-aarch64" ]; then
            export PATH="/opt/android-ndk/toolchains/llvm/prebuilt/linux-aarch64/bin:$PATH"
        elif [ -d "/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64" ]; then
            # NDK might only have x86_64, use that with emulation
            export PATH="/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
        fi
    fi

    # Enable ccache by default if not explicitly disabled
    if [ "${USE_CCACHE:-1}" = "1" ]; then
        export CC="ccache ${CC:-gcc}"
        export CXX="ccache ${CXX:-g++}"
        export CCACHE_DIR="${CCACHE_DIR:-/workspace/.ccache}"
        mkdir -p "$CCACHE_DIR" 2>/dev/null || true
    fi

    # Auto-detect number of CPU cores for parallel builds
    if [ -z "$PARALLEL_JOBS" ]; then
        PARALLEL_JOBS=$(nproc 2>/dev/null || echo 4)
        export MAKEFLAGS="-j${PARALLEL_JOBS}"
    fi

    # Default pkg-config path
    if [ -z "$PKG_CONFIG_PATH" ]; then
        export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig"
    fi

    # If TARGET is set, auto-configure for that target
    if [ -n "$TARGET" ]; then
        setup_target "$TARGET"
    fi
}

# Main entrypoint logic
main() {
    # Handle special commands
    case "${1:-}" in
        --help|-h|help)
            show_help
            exit 0
            ;;
        --version|-v|version)
            show_version
            exit 0
            ;;
        --info|info)
            show_version
            exit 0
            ;;
        --list-targets|list-targets)
            list_targets
            exit 0
            ;;
        --setup)
            setup_target "$2"
            exit $?
            ;;
        --shell|shell)
            init_environment
            print_success "Starting interactive shell..."
            exec /bin/bash
            ;;
        "")
            # No command provided, start interactive shell
            init_environment
            print_info "No command specified. Starting interactive shell."
            print_info "Run 'toolchain-info' to see available tools."
            print_info "Run 'exit' to quit."
            exec /bin/bash
            ;;
        *)
            # Execute the provided command
            init_environment
            exec "$@"
            ;;
    esac
}

# Run main with all arguments
main "$@"
