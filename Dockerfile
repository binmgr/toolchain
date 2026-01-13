# General-purpose static binary build environment
# Based on Alpine Linux with musl libc for truly portable static binaries
#
# Supports building static binaries for:
# - Linux (AMD64, ARM64) - truly static with musl
# - Windows (AMD64, ARM64) - static with MinGW
# - macOS (future support)
# - BSD (future support)
#
# Image: ghcr.io/binmgr/toolchain
# Tags: latest, YYMM (e.g., 2601), commit-SHA

FROM alpine:latest

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
LABEL binmgr.toolchain.languages="c,c++,rust,go,zig,nodejs,python,perl"
LABEL binmgr.toolchain.targets="linux-amd64,linux-arm64,windows-amd64,windows-arm64,darwin-amd64,darwin-arm64"
LABEL binmgr.toolchain.libc="musl"
LABEL binmgr.toolchain.static="true"
LABEL binmgr.toolchain.compilers="gcc,clang,rustc,go,zig"
LABEL binmgr.toolchain.build-systems="make,cmake,meson,ninja,cargo,go-build"

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
    # Scripting and modern languages
    python3 perl \
    go \
    rust cargo \
    nodejs npm \
    && rm -rf /var/cache/apk/*

# Download and install cross-compilers and modern toolchains in a single layer
WORKDIR /opt
RUN set -ex && \
    # ARM64 Linux cross-compiler (Bootlin musl toolchain)
    wget -q https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--musl--stable-2024.02-1.tar.bz2 && \
    tar xjf aarch64--musl--stable-2024.02-1.tar.bz2 && \
    mv aarch64--musl--stable-2024.02-1 aarch64-linux-musl && \
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
    # Zig (excellent for cross-compilation, can replace C/C++ compiler)
    wget -q https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz && \
    tar xJf zig-linux-x86_64-0.13.0.tar.xz && \
    ln -s zig-linux-x86_64-0.13.0 zig && \
    # Clean up all downloads and unnecessary files
    rm -f *.tar.* *.tar.bz2 *.tar.xz && \
    # Strip documentation to save space (~200MB savings)
    rm -rf */share/doc */share/man */share/info */share/gtk-doc 2>/dev/null || true && \
    # Remove locale files (not needed for builds, ~50MB savings)
    rm -rf */share/locale 2>/dev/null || true && \
    # Clean up build artifacts
    find . -type f -name "*.o" -delete 2>/dev/null || true && \
    # Remove test files and examples (~100MB savings)
    find . -type d -name "test" -o -name "tests" -o -name "examples" | xargs rm -rf 2>/dev/null || true

# Add all cross-compilers and modern toolchains to PATH
ENV PATH="/opt/aarch64-linux-musl/bin:/opt/llvm-mingw/bin:/opt/osxcross/target/bin:/opt/zig:${PATH}"

# Create toolchain info script
RUN printf '#!/bin/sh\n\
echo "=== C/C++ Cross-Compilers ==="\n\
echo "Linux AMD64:   CC=gcc CXX=g++"\n\
echo "Linux ARM64:   CC=aarch64-linux-gcc CXX=aarch64-linux-g++"\n\
echo "Windows AMD64: CC=x86_64-w64-mingw32-clang CXX=x86_64-w64-mingw32-clang++"\n\
echo "Windows ARM64: CC=aarch64-w64-mingw32-clang CXX=aarch64-w64-mingw32-clang++"\n\
echo "macOS AMD64:   CC=x86_64-apple-darwin23-clang CXX=x86_64-apple-darwin23-clang++"\n\
echo "macOS ARM64:   CC=aarch64-apple-darwin23-clang CXX=aarch64-apple-darwin23-clang++"\n\
echo ""\n\
echo "=== Modern Languages ==="\n\
echo "Rust:   rustc $(rustc --version 2>/dev/null | cut -d\" \" -f2)"\n\
echo "Go:     go $(go version 2>/dev/null | cut -d\" \" -f3)"\n\
echo "Zig:    zig $(zig version 2>/dev/null)"\n\
echo "Node:   node $(node --version 2>/dev/null)"\n\
echo "Python: python $(python3 --version 2>/dev/null | cut -d\" \" -f2)"\n\
' > /usr/local/bin/toolchain-info && \
    chmod +x /usr/local/bin/toolchain-info

# Set working directory
WORKDIR /workspace

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
    echo "" && \
    echo "=== Modern Languages ===" && \
    echo "Rust:   $(rustc --version)" && \
    echo "Go:     $(go version)" && \
    echo "Zig:    $(zig version)" && \
    echo "Node:   $(node --version)" && \
    echo "Python: $(python3 --version)" && \
    echo "" && \
    echo "=== All toolchains ready ==="

# Add build instructions as environment variable
ENV BUILD_INFO="Alpine-based toolchain for static binaries. Use 'use-compiler <target>' to configure."
