#!/bin/bash
# =============================================================================
# binmgr/toolchain entrypoint script
# =============================================================================
# Configures the build environment for cross-compilation and static binary builds
# Supports 20+ compilation targets across multiple OS families
#
# Usage:
#   --help              Show help message
#   --version/--info    Show toolchain information
#   --list-targets      List available compilation targets
#   --setup TARGET      Configure environment for target
#   --test TARGET       Compile and run test for target
#   --check-static BIN  Verify binary is statically linked
#   --size-report BIN   Show binary size breakdown
#   --shell             Start interactive shell
#   <command>           Execute command with configured environment
# =============================================================================

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
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}info${NC} $*"
}

print_success() {
    echo -e "${GREEN}ok${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}warn${NC} $*"
}

print_error() {
    echo -e "${RED}error${NC} $*" >&2
}

print_header() {
    echo -e "${CYAN}$*${NC}"
    echo -e "${CYAN}$(printf '%.0s-' {1..50})${NC}"
}

# =============================================================================
# PROJECT AUTO-DETECTION
# =============================================================================

detect_project_type() {
    local dir="${1:-.}"
    local detected=""
    local build_system=""
    local language=""

    print_header "Auto-detecting project type in: $dir"

    # Check for various project configuration files
    # Order matters - more specific checks first

    # Gradle/Android/Kotlin
    if [ -f "$dir/build.gradle.kts" ] || [ -f "$dir/build.gradle" ]; then
        if [ -f "$dir/settings.gradle.kts" ] || [ -f "$dir/settings.gradle" ]; then
            build_system="gradle"
            if grep -q "android" "$dir/build.gradle"* 2>/dev/null || [ -d "$dir/app" ]; then
                detected="android"
                language="kotlin/java"
                print_success "Detected: Android project (Gradle)"
            else
                detected="kotlin"
                language="kotlin/java"
                print_success "Detected: Kotlin/Java project (Gradle)"
            fi
        fi
    fi

    # Maven
    if [ -z "$detected" ] && [ -f "$dir/pom.xml" ]; then
        detected="java"
        build_system="maven"
        language="java"
        print_success "Detected: Java project (Maven)"
    fi

    # Rust/Cargo
    if [ -z "$detected" ] && [ -f "$dir/Cargo.toml" ]; then
        detected="rust"
        build_system="cargo"
        language="rust"
        print_success "Detected: Rust project (Cargo)"
    fi

    # Go
    if [ -z "$detected" ] && [ -f "$dir/go.mod" ]; then
        detected="go"
        build_system="go"
        language="go"
        print_success "Detected: Go project (Go Modules)"
    fi

    # Dart
    if [ -z "$detected" ] && [ -f "$dir/pubspec.yaml" ]; then
        detected="dart"
        build_system="dart"
        language="dart"
        print_success "Detected: Dart project (pubspec.yaml)"
    fi

    # Zig
    if [ -z "$detected" ] && [ -f "$dir/build.zig" ]; then
        detected="zig"
        build_system="zig"
        language="zig"
        print_success "Detected: Zig project"
    fi

    # CMake
    if [ -z "$detected" ] && [ -f "$dir/CMakeLists.txt" ]; then
        detected="cmake"
        build_system="cmake"
        language="c/c++"
        print_success "Detected: C/C++ project (CMake)"
    fi

    # Meson
    if [ -z "$detected" ] && [ -f "$dir/meson.build" ]; then
        detected="meson"
        build_system="meson"
        language="c/c++"
        print_success "Detected: C/C++ project (Meson)"
    fi

    # Autotools (configure script)
    if [ -z "$detected" ] && [ -f "$dir/configure" ]; then
        detected="autotools"
        build_system="autotools"
        language="c/c++"
        print_success "Detected: C/C++ project (Autotools/configure)"
    fi

    # Autotools (configure.ac - needs autoreconf)
    if [ -z "$detected" ] && [ -f "$dir/configure.ac" ]; then
        detected="autotools-autoreconf"
        build_system="autotools"
        language="c/c++"
        print_success "Detected: C/C++ project (Autotools - needs autoreconf)"
    fi

    # Makefile (generic)
    if [ -z "$detected" ] && [ -f "$dir/Makefile" ]; then
        detected="make"
        build_system="make"
        language="c/c++"
        print_success "Detected: C/C++ project (Makefile)"
    fi

    # WebAssembly (wasm-pack for Rust)
    if [ -z "$detected" ] && [ -f "$dir/Cargo.toml" ] && grep -q "wasm" "$dir/Cargo.toml" 2>/dev/null; then
        detected="wasm-rust"
        build_system="wasm-pack"
        language="rust"
        print_success "Detected: WebAssembly project (Rust/wasm-pack)"
    fi

    # Not detected
    if [ -z "$detected" ]; then
        print_warning "Could not auto-detect project type"
        echo ""
        echo "Supported project types (static binary output):"
        echo "  - Rust (Cargo.toml)"
        echo "  - Go (go.mod)"
        echo "  - Dart (pubspec.yaml)"
        echo "  - Zig (build.zig)"
        echo "  - C/C++ with CMake (CMakeLists.txt)"
        echo "  - C/C++ with Meson (meson.build)"
        echo "  - C/C++ with Autotools (configure, configure.ac)"
        echo "  - C/C++ with Make (Makefile)"
        echo "  - Android/Kotlin (build.gradle, build.gradle.kts)"
        echo "  - Java with Maven (pom.xml)"
        echo "  - WebAssembly (wasm-pack, wasi-sdk)"
        echo ""
        echo "Note: Interpreted languages (Node.js, Python, etc.) are not"
        echo "      supported for auto-build. Use devenvmgr/interpreters instead."
        return 1
    fi

    # Export detected values
    export PROJECT_TYPE="$detected"
    export BUILD_SYSTEM="$build_system"
    export PROJECT_LANGUAGE="$language"

    echo ""
    echo "Project configuration:"
    echo "  Type:         $detected"
    echo "  Build system: $build_system"
    echo "  Language:     $language"
    echo ""

    # Suggest build commands
    echo "Suggested build commands:"
    case "$detected" in
        android)
            echo "  ./gradlew assembleDebug     # Build debug APK"
            echo "  ./gradlew assembleRelease   # Build release APK"
            echo "  ./gradlew build             # Build all variants"
            ;;
        kotlin|java)
            echo "  ./gradlew build             # Build project"
            echo "  ./gradlew test              # Run tests"
            echo "  ./gradlew jar               # Create JAR"
            ;;
        maven)
            echo "  mvn package                 # Build project"
            echo "  mvn test                    # Run tests"
            echo "  mvn clean install           # Clean and install"
            ;;
        rust)
            echo "  cargo build --release       # Build release"
            echo "  cargo build --target <T>    # Cross-compile"
            echo "  cargo test                  # Run tests"
            ;;
        go)
            echo "  go build                    # Build"
            echo "  GOOS=<os> GOARCH=<arch> go build  # Cross-compile"
            echo "  go test ./...               # Run tests"
            ;;
        dart)
            echo "  dart compile exe bin/main.dart        # Compile to native executable"
            echo "  dart compile exe -o app bin/main.dart # Compile with custom output name"
            echo "  dart pub get                          # Get dependencies"
            echo "  dart test                             # Run tests"
            ;;
        zig)
            echo "  zig build                   # Build"
            echo "  zig build -Dtarget=<T>      # Cross-compile"
            ;;
        cmake)
            echo "  mkdir build && cd build && cmake .. && make"
            echo "  cmake --build build         # Build"
            ;;
        meson)
            echo "  meson setup build && ninja -C build"
            ;;
        autotools)
            echo "  ./configure && make         # Build"
            echo "  ./configure --host=<T>      # Cross-compile"
            ;;
        autotools-autoreconf)
            echo "  autoreconf -fi && ./configure && make"
            ;;
        make)
            echo "  make                        # Build"
            echo "  make CC=\$CC                 # Build with cross-compiler"
            ;;
        wasm-rust)
            echo "  wasm-pack build --release   # Build WASM package"
            echo "  wasm-pack build --target web  # For web browsers"
            ;;
    esac
    echo ""
}

# =============================================================================
# AUTO-BUILD
# =============================================================================

auto_build() {
    local dir="${1:-.}"

    # First detect project type
    detect_project_type "$dir" || return 1

    print_info "Starting auto-build for $PROJECT_TYPE project..."
    echo ""

    case "$PROJECT_TYPE" in
        android)
            if [ -f "$dir/gradlew" ]; then
                chmod +x "$dir/gradlew"
                "$dir/gradlew" assembleRelease
            else
                gradle assembleRelease
            fi
            ;;
        kotlin|java)
            if [ -f "$dir/gradlew" ]; then
                chmod +x "$dir/gradlew"
                "$dir/gradlew" build
            else
                gradle build
            fi
            ;;
        maven)
            mvn package -DskipTests
            ;;
        rust)
            if [ -n "$TARGET" ]; then
                cargo build --release --target "$TARGET"
            else
                cargo build --release
            fi
            ;;
        go)
            if [ -n "$TARGET" ]; then
                # Parse TARGET into GOOS and GOARCH
                local goos goarch
                case "$TARGET" in
                    linux-amd64)    goos=linux;   goarch=amd64 ;;
                    linux-arm64)    goos=linux;   goarch=arm64 ;;
                    linux-armv7)    goos=linux;   goarch=arm ;;
                    linux-riscv64)  goos=linux;   goarch=riscv64 ;;
                    windows-amd64)  goos=windows; goarch=amd64 ;;
                    windows-arm64)  goos=windows; goarch=arm64 ;;
                    darwin-amd64)   goos=darwin;  goarch=amd64 ;;
                    darwin-arm64)   goos=darwin;  goarch=arm64 ;;
                    freebsd-amd64)  goos=freebsd; goarch=amd64 ;;
                    freebsd-arm64)  goos=freebsd; goarch=arm64 ;;
                    android-arm64)  goos=android; goarch=arm64 ;;
                    android-armv7)  goos=android; goarch=arm ;;
                    wasi)           goos=wasip1;  goarch=wasm ;;
                    *)              print_error "Unknown Go target: $TARGET"; return 1 ;;
                esac
                CGO_ENABLED=0 GOOS=$goos GOARCH=$goarch go build -ldflags="-s -w" ./...
            else
                CGO_ENABLED=0 go build -ldflags="-s -w" ./...
            fi
            ;;
        dart)
            dart pub get
            # Find main entry point
            local main_file=""
            if [ -f "$dir/bin/main.dart" ]; then
                main_file="bin/main.dart"
            elif [ -f "$dir/bin/app.dart" ]; then
                main_file="bin/app.dart"
            else
                # Try to find any dart file in bin/
                main_file=$(find "$dir/bin" -name "*.dart" 2>/dev/null | head -1)
            fi
            if [ -n "$main_file" ]; then
                local output_name=$(basename "${main_file%.dart}")
                dart compile exe "$main_file" -o "$output_name"
            else
                print_error "No main Dart file found in bin/"
                return 1
            fi
            ;;
        zig)
            zig build -Doptimize=ReleaseFast
            ;;
        cmake)
            mkdir -p build
            cd build
            cmake -DCMAKE_BUILD_TYPE=Release ..
            make -j$(nproc)
            ;;
        meson)
            meson setup build --buildtype=release
            ninja -C build
            ;;
        autotools)
            ./configure
            make -j$(nproc)
            ;;
        autotools-autoreconf)
            autoreconf -fi
            ./configure
            make -j$(nproc)
            ;;
        make)
            make -j$(nproc)
            ;;
        wasm-rust)
            wasm-pack build --release
            ;;
        *)
            print_error "No auto-build available for: $PROJECT_TYPE"
            return 1
            ;;
    esac

    print_success "Auto-build completed!"
}

# =============================================================================
# HELP
# =============================================================================

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
    --test TARGET       Compile hello world and test for TARGET
    --check-static BIN  Verify binary is statically linked
    --size-report BIN   Show binary size breakdown
    --detect [DIR]      Auto-detect project type from config files
    --auto-build [DIR]  Auto-detect and build project
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
    USE_SCCACHE         Use sccache instead of ccache (default: 0)
    USE_MOLD            Use mold linker (default: 0)
    CCACHE_DIR          ccache directory (default: /workspace/.ccache)
    PARALLEL_JOBS       Number of parallel build jobs (default: auto-detect)

    ${GREEN}Static Linking:${NC}
    ENABLE_STATIC       Force static linking (default: 1)
    LDFLAGS             Linker flags (auto-configured for static builds)

    ${GREEN}Package Config:${NC}
    PKG_CONFIG_PATH     pkg-config search path (auto-configured per target)
    PKG_CONFIG          pkg-config binary (target-specific wrapper)

${YELLOW}AVAILABLE TARGETS:${NC}
    ${GREEN}Linux:${NC}          linux-amd64, linux-arm64, linux-armv7, linux-riscv64
    ${GREEN}Windows:${NC}        windows-amd64, windows-arm64
    ${GREEN}macOS:${NC}          darwin-amd64, darwin-arm64
    ${GREEN}FreeBSD:${NC}        freebsd-amd64, freebsd-arm64
    ${GREEN}OpenBSD:${NC}        openbsd-amd64, openbsd-arm64
    ${GREEN}NetBSD:${NC}         netbsd-amd64, netbsd-arm64
    ${GREEN}illumos:${NC}        illumos-amd64
    ${GREEN}Android:${NC}        android-arm64, android-armv7, android-x86_64, android-x86
    ${GREEN}WebAssembly:${NC}    wasi
    ${GREEN}Universal:${NC}      cosmo

${YELLOW}EXAMPLES:${NC}
    # Show toolchain information
    docker run --rm ghcr.io/${IMAGE_NAME}:latest --info

    # Build for Linux ARM64
    docker run --rm -v \$(pwd):/workspace -e TARGET=linux-arm64 \\
        ghcr.io/${IMAGE_NAME}:latest make

    # Test a target with hello world
    docker run --rm ghcr.io/${IMAGE_NAME}:latest --test linux-arm64

    # Check if binary is static
    docker run --rm -v \$(pwd):/workspace \\
        ghcr.io/${IMAGE_NAME}:latest --check-static ./myprogram

    # Build with mold linker (faster)
    docker run --rm -v \$(pwd):/workspace -e USE_MOLD=1 \\
        ghcr.io/${IMAGE_NAME}:latest make

    # Build universal binary with Cosmopolitan
    docker run --rm -v \$(pwd):/workspace -e TARGET=cosmo \\
        ghcr.io/${IMAGE_NAME}:latest make

${YELLOW}MORE INFORMATION:${NC}
    Repository: https://github.com/binmgr/toolchain
    Issues:     https://github.com/binmgr/toolchain/issues
    Docs:       https://github.com/binmgr/toolchain/blob/main/README.md

EOF
}

# =============================================================================
# VERSION/INFO
# =============================================================================

show_version() {
    print_header "binmgr/toolchain v${TOOLCHAIN_VERSION}"
    echo ""
    toolchain-info
}

# =============================================================================
# LIST TARGETS
# =============================================================================

list_targets() {
    print_header "Available Compilation Targets"
    echo ""
    echo -e "${GREEN}Linux (musl):${NC}"
    echo "  linux-amd64        Native x86_64 with musl libc"
    echo "  linux-arm64        ARM64/AArch64 with musl libc"
    echo "  linux-armv7        ARMv7 32-bit with musl libc"
    echo "  linux-riscv64      RISC-V 64-bit with musl libc"
    echo ""
    echo -e "${GREEN}Windows (MinGW-w64 GCC):${NC}"
    echo "  windows-amd64      x86_64 Windows (MinGW-w64 GCC)"
    echo "  windows-arm64      ARM64 Windows (not supported - uses AMD64)"
    echo ""
    echo -e "${GREEN}macOS (OSXCross):${NC}"
    echo "  darwin-amd64       x86_64 macOS (Darwin 23)"
    echo "  darwin-arm64       ARM64 Apple Silicon (Darwin 23)"
    echo ""
    echo -e "${GREEN}FreeBSD:${NC}"
    echo "  freebsd-amd64      x86_64 FreeBSD 14"
    echo "  freebsd-arm64      ARM64 FreeBSD 14"
    echo ""
    echo -e "${GREEN}OpenBSD:${NC}"
    echo "  openbsd-amd64      x86_64 OpenBSD"
    echo "  openbsd-arm64      ARM64 OpenBSD"
    echo ""
    echo -e "${GREEN}NetBSD:${NC}"
    echo "  netbsd-amd64       x86_64 NetBSD"
    echo "  netbsd-arm64       ARM64 NetBSD"
    echo ""
    echo -e "${GREEN}illumos/Solaris:${NC}"
    echo "  illumos-amd64      x86_64 illumos/Solaris"
    echo ""
    echo -e "${GREEN}Android (NDK r27c, API 24+):${NC}"
    echo "  android-arm64      ARM64-v8a (aarch64)"
    echo "  android-armv7      ARMv7-a (32-bit ARM)"
    echo "  android-x86_64     x86_64 (Intel/AMD 64-bit)"
    echo "  android-x86        x86 (Intel/AMD 32-bit)"
    echo ""
    echo -e "${GREEN}WebAssembly:${NC}"
    echo "  wasi               WebAssembly System Interface (wasi-sdk)"
    echo ""
    echo -e "${GREEN}Universal Binary:${NC}"
    echo "  cosmo              Cosmopolitan (runs on Linux/macOS/Windows/BSD)"
    echo ""
}

# =============================================================================
# SETUP TARGET
# =============================================================================

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
    export ENABLE_STATIC=1

    case "$target" in
        # =====================================================================
        # LINUX TARGETS
        # =====================================================================
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
        linux-armv7)
            export CC=armv7-linux-gcc
            export CXX=armv7-linux-g++
            export AR=armv7-linux-ar
            export RANLIB=armv7-linux-ranlib
            export STRIP=armv7-linux-strip
            export PKG_CONFIG_PATH="/opt/armv7-linux-musl/arm-buildroot-linux-musleabihf/sysroot/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        linux-riscv64)
            export CC=riscv64-linux-gcc
            export CXX=riscv64-linux-g++
            export AR=riscv64-linux-ar
            export RANLIB=riscv64-linux-ranlib
            export STRIP=riscv64-linux-strip
            export PKG_CONFIG_PATH="/opt/riscv64-linux-musl/riscv64-buildroot-linux-musl/sysroot/usr/lib/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        # =====================================================================
        # WINDOWS TARGETS (Alpine's native MinGW-w64 GCC)
        # =====================================================================
        windows-amd64)
            export CC=x86_64-w64-mingw32-gcc
            export CXX=x86_64-w64-mingw32-g++
            export AR=x86_64-w64-mingw32-ar
            export RANLIB=x86_64-w64-mingw32-ranlib
            export STRIP=x86_64-w64-mingw32-strip
            export PKG_CONFIG_PATH="/usr/x86_64-w64-mingw32/lib/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        windows-arm64)
            # ARM64 Windows cross-compilation not supported with Alpine's MinGW
            # Fall back to x86_64 Windows
            print_warning "ARM64 Windows not supported - using AMD64 instead"
            export CC=x86_64-w64-mingw32-gcc
            export CXX=x86_64-w64-mingw32-g++
            export AR=x86_64-w64-mingw32-ar
            export RANLIB=x86_64-w64-mingw32-ranlib
            export STRIP=x86_64-w64-mingw32-strip
            export PKG_CONFIG_PATH="/usr/x86_64-w64-mingw32/lib/pkgconfig"
            export LDFLAGS="-static"
            export CFLAGS="${CFLAGS:--O2} -static"
            ;;
        # =====================================================================
        # MACOS TARGETS
        # =====================================================================
        darwin-amd64)
            export CC=x86_64-apple-darwin23-clang
            export CXX=x86_64-apple-darwin23-clang++
            export AR=x86_64-apple-darwin23-ar
            export RANLIB=x86_64-apple-darwin23-ranlib
            export STRIP=x86_64-apple-darwin23-strip
            export PKG_CONFIG_PATH="/opt/osxcross/target/SDK/MacOSX14.0.sdk/usr/lib/pkgconfig"
            # macOS doesn't support fully static binaries
            ;;
        darwin-arm64)
            export CC=aarch64-apple-darwin23-clang
            export CXX=aarch64-apple-darwin23-clang++
            export AR=aarch64-apple-darwin23-ar
            export RANLIB=aarch64-apple-darwin23-ranlib
            export STRIP=aarch64-apple-darwin23-strip
            export PKG_CONFIG_PATH="/opt/osxcross/target/SDK/MacOSX14.0.sdk/usr/lib/pkgconfig"
            ;;
        # =====================================================================
        # BSD TARGETS
        # =====================================================================
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
        # =====================================================================
        # ILLUMOS/SOLARIS
        # =====================================================================
        illumos-amd64)
            export CC=x86_64-illumos-clang
            export CXX=x86_64-illumos-clang++
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export PKG_CONFIG_PATH="/opt/illumos-cross/lib/pkgconfig"
            export LDFLAGS="-static"
            ;;
        # =====================================================================
        # ANDROID TARGETS
        # =====================================================================
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
        # =====================================================================
        # WEBASSEMBLY TARGETS
        # =====================================================================
        wasi)
            # Alpine's native wasi-sdk package (requires lld linker)
            export CC="clang --target=wasm32-wasi --sysroot=/usr/share/wasi-sysroot -fuse-ld=lld"
            export CXX="clang++ --target=wasm32-wasi --sysroot=/usr/share/wasi-sysroot -fuse-ld=lld"
            export AR=llvm-ar
            export RANLIB=llvm-ranlib
            export STRIP=llvm-strip
            export WASI_SDK_PATH=/usr/share/wasi-sysroot
            ;;
        # =====================================================================
        # COSMOPOLITAN (UNIVERSAL BINARY)
        # =====================================================================
        cosmo)
            export CC=cosmocc
            export CXX=cosmoc++
            export AR=/opt/cosmocc/bin/cosmoar
            export RANLIB=true  # cosmocc doesn't need ranlib
            export STRIP=/opt/cosmocc/bin/cosmostrip
            export COSMOCC_HOME=/opt/cosmocc
            # Cosmo binaries are inherently portable
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

# =============================================================================
# TEST TARGET
# =============================================================================

test_target() {
    local target="$1"

    if [ -z "$target" ]; then
        print_error "No target specified"
        echo "Usage: $0 --test TARGET"
        return 1
    fi

    print_header "Testing compilation for: $target"

    # Create test program
    local test_dir=$(mktemp -d)
    cat > "$test_dir/hello.c" << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello from %s!\n",
#if defined(__linux__)
    "Linux"
#elif defined(_WIN32)
    "Windows"
#elif defined(__APPLE__)
    "macOS"
#elif defined(__FreeBSD__)
    "FreeBSD"
#elif defined(__OpenBSD__)
    "OpenBSD"
#elif defined(__NetBSD__)
    "NetBSD"
#elif defined(__wasm__)
    "WebAssembly"
#elif defined(__COSMOPOLITAN__)
    "Cosmopolitan"
#else
    "Unknown"
#endif
    );
    return 0;
}
EOF

    # Setup target
    setup_target "$target"

    # Compile
    print_info "Compiling test program..."
    local output="$test_dir/hello"

    case "$target" in
        windows-*)
            output="$test_dir/hello.exe"
            ;;
        wasm*|wasi)
            output="$test_dir/hello.wasm"
            ;;
        cosmo)
            output="$test_dir/hello.com"
            ;;
    esac

    # Use timeout to prevent hanging (Bootlin toolchain-wrapper can stall)
    if timeout 60 $CC $CFLAGS $LDFLAGS "$test_dir/hello.c" -o "$output" 2>&1; then
        print_success "Compilation successful!"
        echo ""
        echo "Binary info:"
        file "$output"
        echo ""
        echo "Size: $(ls -lh "$output" | awk '{print $5}')"

        # Try to run if possible (with timeout to prevent hangs)
        case "$target" in
            linux-amd64)
                print_info "Running binary..."
                timeout 10 "$output" || print_warning "Execution failed or timed out"
                ;;
            linux-arm64)
                print_info "Running with QEMU..."
                timeout 30 qemu-aarch64 "$output" 2>/dev/null || print_warning "QEMU execution failed or timed out"
                ;;
            linux-armv7)
                print_info "Running with QEMU..."
                timeout 30 qemu-arm "$output" 2>/dev/null || print_warning "QEMU execution failed or timed out"
                ;;
            linux-riscv64)
                print_info "Running with QEMU..."
                timeout 30 qemu-riscv64 "$output" 2>/dev/null || print_warning "QEMU execution failed or timed out"
                ;;
            wasi)
                print_info "Running with wasmtime..."
                timeout 30 wasmtime "$output" 2>/dev/null || print_warning "Wasmtime execution failed or timed out"
                ;;
            *)
                print_info "Binary created but cannot be executed on this host"
                ;;
        esac
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_error "Compilation timed out after 60 seconds!"
            print_info "The cross-compiler may be hanging. Try running the wrapper directly."
        else
            print_error "Compilation failed!"
        fi
        rm -rf "$test_dir"
        return 1
    fi

    rm -rf "$test_dir"
    echo ""
    print_success "Test passed for $target"
}

# =============================================================================
# CHECK STATIC
# =============================================================================

check_static() {
    local binary="$1"

    if [ -z "$binary" ]; then
        print_error "No binary specified"
        echo "Usage: $0 --check-static BINARY"
        return 1
    fi

    if [ ! -f "$binary" ]; then
        print_error "File not found: $binary"
        return 1
    fi

    print_header "Static Linking Analysis: $binary"
    echo ""

    echo "File type:"
    file "$binary"
    echo ""

    echo "Dynamic dependencies (ldd):"
    if ldd "$binary" 2>&1 | grep -q "not a dynamic executable"; then
        print_success "Binary is statically linked (no dynamic dependencies)"
    elif ldd "$binary" 2>&1 | grep -q "statically linked"; then
        print_success "Binary is statically linked"
    else
        print_warning "Binary has dynamic dependencies:"
        ldd "$binary" 2>&1 | head -20
    fi
    echo ""

    echo "ELF dynamic section (readelf):"
    if command -v readelf &>/dev/null; then
        local needed=$(readelf -d "$binary" 2>/dev/null | grep -E "NEEDED|INTERP" || true)
        if [ -z "$needed" ]; then
            print_success "No NEEDED or INTERP entries (fully static)"
        else
            print_warning "Dynamic entries found:"
            echo "$needed"
        fi
    else
        print_info "readelf not available"
    fi
    echo ""
}

# =============================================================================
# SIZE REPORT
# =============================================================================

size_report() {
    local binary="$1"

    if [ -z "$binary" ]; then
        print_error "No binary specified"
        echo "Usage: $0 --size-report BINARY"
        return 1
    fi

    if [ ! -f "$binary" ]; then
        print_error "File not found: $binary"
        return 1
    fi

    print_header "Size Report: $binary"
    echo ""

    echo "File size:"
    ls -lh "$binary" | awk '{print "  " $5 " (" $5 " bytes)"}'
    echo ""

    echo "Section sizes (size):"
    if command -v size &>/dev/null; then
        size "$binary" 2>/dev/null || print_info "size command failed (may not be ELF)"
    fi
    echo ""

    echo "Sections breakdown (readelf):"
    if command -v readelf &>/dev/null; then
        readelf -S "$binary" 2>/dev/null | head -30 || print_info "readelf failed (may not be ELF)"
    fi
    echo ""

    echo "Optimization suggestions:"
    echo "  1. Strip symbols:    strip --strip-all $binary"
    echo "  2. Compress with UPX: upx --best --lzma $binary"
    echo "  3. Use -Os flag:     Compile with CFLAGS=\"-Os\""
    echo "  4. Remove sections:  strip --remove-section=.comment $binary"
    echo ""
}

# =============================================================================
# INITIALIZE ENVIRONMENT
# =============================================================================

init_environment() {
    # Detect host architecture and add Android NDK to PATH
    local host_arch=$(uname -m)
    if [ "$host_arch" = "x86_64" ]; then
        export PATH="/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
    elif [ "$host_arch" = "aarch64" ]; then
        if [ -d "/opt/android-ndk/toolchains/llvm/prebuilt/linux-aarch64" ]; then
            export PATH="/opt/android-ndk/toolchains/llvm/prebuilt/linux-aarch64/bin:$PATH"
        elif [ -d "/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64" ]; then
            export PATH="/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
        fi
    fi

    # Enable ccache by default if not explicitly disabled
    if [ "${USE_CCACHE:-1}" = "1" ] && [ "${USE_SCCACHE:-0}" != "1" ]; then
        export CC="ccache ${CC:-gcc}"
        export CXX="ccache ${CXX:-g++}"
        export CCACHE_DIR="${CCACHE_DIR:-/workspace/.ccache}"
        mkdir -p "$CCACHE_DIR" 2>/dev/null || true
    fi

    # Use sccache if requested
    if [ "${USE_SCCACHE:-0}" = "1" ]; then
        export CC="sccache ${CC:-gcc}"
        export CXX="sccache ${CXX:-g++}"
        export SCCACHE_DIR="${SCCACHE_DIR:-/workspace/.sccache}"
        mkdir -p "$SCCACHE_DIR" 2>/dev/null || true
    fi

    # Use mold linker if requested
    if [ "${USE_MOLD:-0}" = "1" ]; then
        export LDFLAGS="${LDFLAGS:-} -fuse-ld=mold"
        print_info "Using mold linker"
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

# =============================================================================
# MAIN
# =============================================================================

main() {
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
        --test)
            test_target "$2"
            exit $?
            ;;
        --check-static)
            check_static "$2"
            exit $?
            ;;
        --size-report)
            size_report "$2"
            exit $?
            ;;
        --detect)
            detect_project_type "${2:-.}"
            exit $?
            ;;
        --auto-build)
            auto_build "${2:-.}"
            exit $?
            ;;
        --shell|shell)
            init_environment
            print_success "Starting interactive shell..."
            exec /bin/bash
            ;;
        "")
            init_environment
            print_info "No command specified. Starting interactive shell."
            print_info "Run 'toolchain-info' to see available tools."
            print_info "Run 'exit' to quit."
            exec /bin/bash
            ;;
        *)
            init_environment
            exec "$@"
            ;;
    esac
}

main "$@"
