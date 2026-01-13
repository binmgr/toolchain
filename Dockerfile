# General-purpose static binary build environment
# Based on Alpine Linux with musl libc for truly portable static binaries
#
# Supports building static binaries for:
# - Linux (AMD64, ARM64) - truly static with musl
# - Windows (AMD64, ARM64) - static with MinGW
# - macOS (AMD64, ARM64) - via OSXCross
# - BSD (FreeBSD, OpenBSD, NetBSD) - via Clang cross-compilation
# - Android (ARM64, ARMv7, x86_64, x86) - via NDK r27c, API 24+
#
# Image: ghcr.io/binmgr/toolchain
# Tags: latest, YYMM (e.g., 2601), commit-SHA

FROM alpine:latest

# Build arguments for multiarch support
ARG TARGETARCH
ARG BUILDPLATFORM

# OCI Image annotations
LABEL org.opencontainers.image.title="binmgr/toolchain"
LABEL org.opencontainers.image.description="Ultimate cross-compilation toolchain for static binaries across all platforms"
LABEL org.opencontainers.image.authors="binmgr"
LABEL org.opencontainers.image.vendor="binmgr"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/binmgr/toolchain"
LABEL org.opencontainers.image.source="https://github.com/binmgr/toolchain"
LABEL org.opencontainers.image.documentation="https://github.com/binmgr/toolchain/blob/main/README.md"
LABEL org.opencontainers.image.base.name="alpine:latest"

# Custom labels for toolchain capabilities
LABEL binmgr.toolchain.version="2601"
LABEL binmgr.toolchain.languages="c,c++,rust,go,tinygo,zig,nodejs,deno,bun,python,perl,wasm"
LABEL binmgr.toolchain.targets="linux-amd64,linux-arm64,windows-amd64,windows-arm64,darwin-amd64,darwin-arm64,freebsd-amd64,freebsd-arm64,openbsd-amd64,openbsd-arm64,netbsd-amd64,netbsd-arm64,android-arm64,android-armv7,android-x86_64,android-x86,wasm32,wasm64"
LABEL binmgr.toolchain.libc="musl"
LABEL binmgr.toolchain.static="true"
LABEL binmgr.toolchain.compilers="gcc,clang,rustc,go,tinygo,zig,emcc"
LABEL binmgr.toolchain.build-systems="make,cmake,meson,ninja,cargo,go-build"
LABEL binmgr.toolchain.runtimes="node,deno,bun,wasmtime,qemu"
LABEL binmgr.toolchain.tools="ccache,upx,valgrind,shellcheck,doxygen,wasm-pack"
LABEL binmgr.toolchain.android-ndk="r27c"
LABEL binmgr.toolchain.android-api="24+"

# Install build tools, libraries, and cross-compilers in a single layer to reduce image size
RUN apk add --no-cache \
    # Core build tools
    build-base cmake meson ninja pkgconf autoconf automake libtool make patch \
    # Compilers and assemblers
    gcc g++ clang lld llvm nasm yasm \
    # Version control and utilities
    git curl wget rsync bash coreutils grep sed gawk findutils \
    # Archive tools
    xz tar gzip bzip2 zip unzip \
    # Container & archive tools
    squashfs-tools p7zip cpio \
    # Binary utilities
    file binutils upx \
    # Build acceleration
    ccache \
    # QEMU for testing cross-compiled binaries
    qemu-aarch64 qemu-arm qemu-x86_64 qemu-i386 \
    # Code analysis and quality tools
    clang-extra-tools valgrind shellcheck \
    # Documentation tools
    doxygen graphviz \
    # Documentation and release tools
    texinfo github-cli \
    # System headers
    linux-headers musl-dev \
    # Compression libraries (dev + static)
    zlib-dev zlib-static \
    bzip2-dev bzip2-static \
    xz-dev xz-static \
    lz4-dev lz4-static \
    zstd-dev zstd-static \
    # Crypto and SSL
    openssl-dev openssl-libs-static \
    # Terminal/UI
    ncurses-dev ncurses-static \
    readline-dev readline-static \
    # XML/JSON parsing (libxml2-dev and uuid-dev needed for osxcross)
    libxml2-dev libxml2-static \
    expat-dev expat-static \
    util-linux-dev \
    # Image libraries
    libpng-dev libpng-static \
    libjpeg-turbo-dev libjpeg-turbo-static \
    giflib-dev \
    libwebp-dev libwebp-static \
    tiff-dev \
    # Audio/Video codecs (dev packages - FFmpeg will build statically)
    opus-dev \
    libvorbis-dev \
    libogg-dev \
    lame-dev \
    libtheora-dev \
    x264-dev \
    x265-dev \
    libvpx-dev \
    aom-dev \
    dav1d-dev \
    # Font rendering
    freetype-dev freetype-static \
    fontconfig-dev fontconfig-static \
    fribidi-dev fribidi-static \
    harfbuzz-dev harfbuzz-static \
    # Networking
    curl-dev curl-static \
    c-ares-dev \
    nghttp2-dev nghttp2-static \
    libssh2-dev libssh2-static \
    # Database
    sqlite-dev sqlite-static \
    # Data formats
    json-c-dev \
    yaml-dev yaml-static \
    protobuf-dev \
    # Regular expressions
    pcre-dev pcre-static \
    pcre2-dev \
    oniguruma-dev \
    # Math libraries
    gmp-dev mpfr-dev mpc1-dev isl-dev \
    # Additional system libraries
    elfutils-dev \
    libcap-dev libcap-static \
    musl-obstack musl-obstack-dev \
    # Additional static libraries
    libffi-dev \
    gdbm-dev \
    libedit-dev libedit-static \
    libsodium-dev libsodium-static \
    libuv-dev libuv-static \
    # Scripting and modern languages
    python3 perl \
    go \
    rust cargo \
    nodejs npm \
    # Glibc compatibility (needed for some pre-built toolchains)
    gcompat \
    && rm -rf /var/cache/apk/*

# Download and install cross-compilers and modern toolchains in a single layer
WORKDIR /opt
RUN set -ex && \
    # ARM64 Linux cross-compiler (Bootlin musl toolchain)
    wget -q https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--musl--stable-2024.02-1.tar.bz2 && \
    tar xjf aarch64--musl--stable-2024.02-1.tar.bz2 && \
    mv aarch64--musl--stable-2024.02-1 aarch64-linux-musl && \
    # Create standard symlinks for Bootlin toolchain
    cd aarch64-linux-musl/bin && \
    ln -sf aarch64-buildroot-linux-musl-gcc aarch64-linux-gcc && \
    ln -sf aarch64-buildroot-linux-musl-g++ aarch64-linux-g++ && \
    ln -sf aarch64-buildroot-linux-musl-ar aarch64-linux-ar && \
    ln -sf aarch64-buildroot-linux-musl-strip aarch64-linux-strip && \
    cd ../.. && \
    # Windows cross-compiler (LLVM MinGW - supports both AMD64 and ARM64)
    wget -q https://github.com/mstorsjo/llvm-mingw/releases/download/20241217/llvm-mingw-20241217-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    tar xJf llvm-mingw-20241217-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    ln -s llvm-mingw-20241217-ucrt-ubuntu-20.04-x86_64 llvm-mingw && \
    # macOS cross-compiler (OSXCross)
    git clone --depth 1 https://github.com/tpoechtrager/osxcross.git && \
    cd osxcross && \
    wget -q https://github.com/joseluisq/macosx-sdks/releases/download/14.0/MacOSX14.0.sdk.tar.xz -O tarballs/MacOSX14.0.sdk.tar.xz && \
    UNATTENDED=1 ./build.sh && \
    # Clean up OSXCross build artifacts
    rm -rf build tarballs *.sh *.md && \
    cd .. && \
    # Android NDK r27c (supports API 24+ for all architectures)
    # NDK is architecture-specific for the host
    wget -q https://dl.google.com/android/repository/android-ndk-r27c-linux.zip && \
    unzip -q android-ndk-r27c-linux.zip && \
    mv android-ndk-r27c android-ndk && \
    # BSD cross-compilation support using LLVM
    # Create BSD sysroot directories for cross-compilation
    mkdir -p bsd-cross/freebsd/{include,lib} && \
    mkdir -p bsd-cross/openbsd/{include,lib} && \
    mkdir -p bsd-cross/netbsd/{include,lib} && \
    mkdir -p bsd-cross/bin && \
    # Download FreeBSD sysroot (base headers and libs)
    wget -q https://download.freebsd.org/releases/amd64/14.2-RELEASE/base.txz && \
    tar xJf base.txz -C bsd-cross/freebsd --strip-components=1 ./usr/include ./usr/lib ./lib 2>/dev/null || true && \
    # Zig (excellent for cross-compilation, can replace C/C++ compiler)
    # Architecture-aware download
    if [ "$(uname -m)" = "x86_64" ]; then \
        wget -q https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz && \
        tar xJf zig-linux-x86_64-0.13.0.tar.xz && \
        ln -s zig-linux-x86_64-0.13.0 zig; \
    else \
        wget -q https://ziglang.org/download/0.13.0/zig-linux-aarch64-0.13.0.tar.xz && \
        tar xJf zig-linux-aarch64-0.13.0.tar.xz && \
        ln -s zig-linux-aarch64-0.13.0 zig; \
    fi && \
    # Deno - Modern JavaScript/TypeScript runtime
    if [ "$(uname -m)" = "x86_64" ]; then \
        wget -q https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip && \
        unzip -q deno-x86_64-unknown-linux-gnu.zip -d deno; \
    else \
        wget -q https://github.com/denoland/deno/releases/latest/download/deno-aarch64-unknown-linux-gnu.zip && \
        unzip -q deno-aarch64-unknown-linux-gnu.zip -d deno; \
    fi && \
    chmod +x deno/deno && \
    # Bun - Fast JavaScript runtime and bundler
    if [ "$(uname -m)" = "x86_64" ]; then \
        wget -q https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip && \
        unzip -q bun-linux-x64.zip && \
        mv bun-linux-x64 bun; \
    else \
        wget -q https://github.com/oven-sh/bun/releases/latest/download/bun-linux-aarch64.zip && \
        unzip -q bun-linux-aarch64.zip && \
        mv bun-linux-aarch64 bun; \
    fi && \
    # TinyGo - Go compiler for embedded and WebAssembly
    if [ "$(uname -m)" = "x86_64" ]; then \
        wget -q https://github.com/tinygo-org/tinygo/releases/download/v0.34.0/tinygo0.34.0.linux-amd64.tar.gz && \
        tar xzf tinygo0.34.0.linux-amd64.tar.gz; \
    else \
        wget -q https://github.com/tinygo-org/tinygo/releases/download/v0.34.0/tinygo0.34.0.linux-arm64.tar.gz && \
        tar xzf tinygo0.34.0.linux-arm64.tar.gz; \
    fi && \
    # Wasmtime - WebAssembly runtime
    if [ "$(uname -m)" = "x86_64" ]; then \
        wget -q https://github.com/bytecodealliance/wasmtime/releases/latest/download/wasmtime-v27.0.0-x86_64-linux.tar.xz && \
        tar xJf wasmtime-v27.0.0-x86_64-linux.tar.xz && \
        mv wasmtime-v27.0.0-x86_64-linux wasmtime; \
    else \
        wget -q https://github.com/bytecodealliance/wasmtime/releases/latest/download/wasmtime-v27.0.0-aarch64-linux.tar.xz && \
        tar xJf wasmtime-v27.0.0-aarch64-linux.tar.xz && \
        mv wasmtime-v27.0.0-aarch64-linux wasmtime; \
    fi && \
    # Emscripten - C/C++ to WebAssembly compiler
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git && \
    cd emsdk && \
    ./emsdk install latest && \
    ./emsdk activate latest && \
    cd .. && \
    # Install wasm-pack (Rust to WebAssembly packager) via cargo
    cargo install wasm-pack && \
    # Clean up all downloads and unnecessary files
    rm -f *.tar.* *.tar.bz2 *.tar.xz *.zip *.tar.gz && \
    # Strip documentation to save space (~200MB savings)
    rm -rf */share/doc */share/man */share/info */share/gtk-doc 2>/dev/null || true && \
    # Remove locale files (not needed for builds, ~50MB savings)
    rm -rf */share/locale 2>/dev/null || true && \
    # Create BSD cross-compilation wrapper scripts
    printf '#!/bin/sh\nexec clang --target=x86_64-unknown-freebsd14 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/x86_64-freebsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=x86_64-unknown-freebsd14 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/x86_64-freebsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=aarch64-unknown-freebsd14 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/aarch64-freebsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=aarch64-unknown-freebsd14 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/aarch64-freebsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=x86_64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/x86_64-openbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=x86_64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/x86_64-openbsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=aarch64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/aarch64-openbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=aarch64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/aarch64-openbsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=x86_64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/x86_64-netbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=x86_64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/x86_64-netbsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=aarch64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/aarch64-netbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=aarch64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/aarch64-netbsd-clang++ && \
    chmod +x bsd-cross/bin/* && \
    # Clean up build artifacts
    find . -type f -name "*.o" -delete 2>/dev/null || true && \
    # Remove test files and examples (~100MB savings)
    find . -type d -name "test" -o -name "tests" -o -name "examples" | xargs rm -rf 2>/dev/null || true

# Add all cross-compilers and modern toolchains to PATH
# Note: Android NDK path will be added by entrypoint based on host architecture
ENV PATH="/opt/aarch64-linux-musl/bin:/opt/llvm-mingw/bin:/opt/osxcross/target/bin:/opt/bsd-cross/bin:/opt/zig:/opt/deno:/opt/bun:/opt/tinygo/bin:/opt/wasmtime:/opt/emsdk:/opt/emsdk/upstream/emscripten:/root/.cargo/bin:${PATH}" \
    ANDROID_NDK_HOME="/opt/android-ndk" \
    ANDROID_NDK_ROOT="/opt/android-ndk" \
    EMSDK="/opt/emsdk" \
    EM_CONFIG="/opt/emsdk/.emscripten" \
    CCACHE_DIR="/workspace/.ccache" \
    PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig" \
    PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
    PKG_CONFIG_ALLOW_SYSTEM_LIBS=1

# Create pkg-config directories for all cross-compilation targets
RUN mkdir -p /usr/lib/pkgconfig \
    /usr/local/lib/pkgconfig \
    /usr/share/pkgconfig \
    /opt/aarch64-linux-musl/aarch64-buildroot-linux-musl/sysroot/usr/lib/pkgconfig \
    /opt/llvm-mingw/x86_64-w64-mingw32/lib/pkgconfig \
    /opt/llvm-mingw/aarch64-w64-mingw32/lib/pkgconfig \
    /opt/osxcross/target/SDK/MacOSX14.0.sdk/usr/lib/pkgconfig \
    /opt/bsd-cross/freebsd/usr/lib/pkgconfig \
    /opt/bsd-cross/openbsd/usr/lib/pkgconfig \
    /opt/bsd-cross/netbsd/usr/lib/pkgconfig

# Create toolchain info script
RUN printf '#!/bin/sh\n\
echo "=== C/C++ Cross-Compilers ==="\n\
echo "Linux AMD64:    CC=gcc CXX=g++"\n\
echo "Linux ARM64:    CC=aarch64-linux-gcc CXX=aarch64-linux-g++"\n\
echo "Windows AMD64:  CC=x86_64-w64-mingw32-clang CXX=x86_64-w64-mingw32-clang++"\n\
echo "Windows ARM64:  CC=aarch64-w64-mingw32-clang CXX=aarch64-w64-mingw32-clang++"\n\
echo "macOS AMD64:    CC=x86_64-apple-darwin23-clang CXX=x86_64-apple-darwin23-clang++"\n\
echo "macOS ARM64:    CC=aarch64-apple-darwin23-clang CXX=aarch64-apple-darwin23-clang++"\n\
echo "FreeBSD AMD64:  CC=x86_64-freebsd-clang CXX=x86_64-freebsd-clang++"\n\
echo "FreeBSD ARM64:  CC=aarch64-freebsd-clang CXX=aarch64-freebsd-clang++"\n\
echo "OpenBSD AMD64:  CC=x86_64-openbsd-clang CXX=x86_64-openbsd-clang++"\n\
echo "OpenBSD ARM64:  CC=aarch64-openbsd-clang CXX=aarch64-openbsd-clang++"\n\
echo "NetBSD AMD64:   CC=x86_64-netbsd-clang CXX=x86_64-netbsd-clang++"\n\
echo "NetBSD ARM64:   CC=aarch64-netbsd-clang CXX=aarch64-netbsd-clang++"\n\
echo ""\n\
echo "=== Android NDK (API 24+) ==="\n\
echo "ARM64 (v8a):    CC=aarch64-linux-android24-clang CXX=aarch64-linux-android24-clang++"\n\
echo "ARMv7 (v7a):    CC=armv7a-linux-androideabi24-clang CXX=armv7a-linux-androideabi24-clang++"\n\
echo "x86_64:         CC=x86_64-linux-android24-clang CXX=x86_64-linux-android24-clang++"\n\
echo "x86:            CC=i686-linux-android24-clang CXX=i686-linux-android24-clang++"\n\
echo ""\n\
echo "=== Modern Languages ==="\n\
echo "Rust:    rustc $(rustc --version 2>/dev/null | cut -d\" \" -f2)"\n\
echo "Go:      go $(go version 2>/dev/null | cut -d\" \" -f3)"\n\
echo "TinyGo:  $(tinygo version 2>/dev/null)"\n\
echo "Zig:     zig $(zig version 2>/dev/null)"\n\
echo "Node.js: node $(node --version 2>/dev/null)"\n\
echo "Deno:    deno $(deno --version 2>/dev/null | head -1 | cut -d\" \" -f2)"\n\
echo "Bun:     bun $(bun --version 2>/dev/null)"\n\
echo "Python:  python $(python3 --version 2>/dev/null | cut -d\" \" -f2)"\n\
echo ""\n\
echo "=== WebAssembly Toolchain ==="\n\
echo "wasm-pack:  $(wasm-pack --version 2>/dev/null)"\n\
echo "wasmtime:   $(wasmtime --version 2>/dev/null)"\n\
echo "emcc:       $(emcc --version 2>/dev/null | head -1)"\n\
' > /usr/local/bin/toolchain-info && \
    chmod +x /usr/local/bin/toolchain-info

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Verify all toolchains and languages are available
RUN echo "=== Toolchain Verification ===" && \
    echo "Alpine: $(cat /etc/alpine-release)" && \
    echo "Architecture: $(uname -m)" && \
    echo "" && \
    echo "=== C/C++ Compilers ===" && \
    echo "GCC (Linux AMD64):      $(gcc --version | head -1)" && \
    echo "GCC (Linux ARM64):      $(aarch64-linux-gcc --version | head -1)" && \
    echo "Clang (Windows AMD64):  $(x86_64-w64-mingw32-clang --version | head -1)" && \
    echo "Clang (Windows ARM64):  $(aarch64-w64-mingw32-clang --version | head -1)" && \
    echo "Clang (macOS AMD64):    $(x86_64-apple-darwin23-clang --version 2>&1 | head -1)" && \
    echo "Clang (macOS ARM64):    $(aarch64-apple-darwin23-clang --version 2>&1 | head -1)" && \
    echo "Clang (FreeBSD AMD64):  $(x86_64-freebsd-clang --version 2>&1 | head -1)" && \
    echo "Clang (FreeBSD ARM64):  $(aarch64-freebsd-clang --version 2>&1 | head -1)" && \
    echo "Clang (OpenBSD AMD64):  $(x86_64-openbsd-clang --version 2>&1 | head -1)" && \
    echo "Clang (OpenBSD ARM64):  $(aarch64-openbsd-clang --version 2>&1 | head -1)" && \
    echo "Clang (NetBSD AMD64):   $(x86_64-netbsd-clang --version 2>&1 | head -1)" && \
    echo "Clang (NetBSD ARM64):   $(aarch64-netbsd-clang --version 2>&1 | head -1)" && \
    echo "" && \
    echo "=== Android NDK ===" && \
    echo "NDK Version:            $(cat /opt/android-ndk/source.properties | grep Pkg.Revision | cut -d= -f2)" && \
    echo "ARM64-v8a:              $(aarch64-linux-android24-clang --version | head -1)" && \
    echo "ARMv7-a:                $(armv7a-linux-androideabi24-clang --version | head -1)" && \
    echo "x86_64:                 $(x86_64-linux-android24-clang --version | head -1)" && \
    echo "x86:                    $(i686-linux-android24-clang --version | head -1)" && \
    echo "" && \
    echo "=== Modern Languages ===" && \
    echo "Rust:    $(rustc --version)" && \
    echo "Go:      $(go version)" && \
    echo "TinyGo:  $(tinygo version)" && \
    echo "Zig:     $(zig version)" && \
    echo "Node.js: $(node --version)" && \
    echo "Deno:    $(deno --version | head -1)" && \
    echo "Bun:     $(bun --version)" && \
    echo "Python:  $(python3 --version)" && \
    echo "" && \
    echo "=== WebAssembly Toolchain ===" && \
    echo "wasm-pack: $(wasm-pack --version)" && \
    echo "wasmtime:  $(wasmtime --version)" && \
    echo "emcc:      $(emcc --version | head -1)" && \
    echo "" && \
    echo "=== Build Tools ===" && \
    echo "ccache:    $(ccache --version | head -1)" && \
    echo "upx:       $(upx --version | head -1)" && \
    echo "doxygen:   $(doxygen --version)" && \
    echo "valgrind:  $(valgrind --version)" && \
    echo "shellcheck: $(shellcheck --version | grep version:)" && \
    echo "" && \
    echo "=== All toolchains ready ==="

# Add build instructions as environment variable
ENV BUILD_INFO="Alpine-based toolchain for static binaries. Use 'use-compiler <target>' to configure."

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--shell"]
