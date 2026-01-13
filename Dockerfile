# General-purpose static binary build environment
# Based on Alpine Linux with musl libc for truly portable static binaries
#
# Supports building static binaries for:
# - Linux (AMD64, ARM64) - truly static with musl
# - Windows (AMD64, ARM64) - static with MinGW
# - macOS (future support)
# - BSD (future support)
#
# Image: ghcr.io/binmgr/cc
# Tags: latest, YYMM (e.g., 2601), commit-SHA

FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/binmgr/toolchain"
LABEL org.opencontainers.image.description="Alpine-based toolchain for building truly static binaries"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="binmgr"

# Install base build tools and dependencies
# These packages provide everything needed for building C/C++ projects statically
RUN apk add --no-cache \
    # Core build tools
    build-base \
    cmake \
    meson \
    ninja \
    pkgconf \
    autoconf \
    automake \
    libtool \
    make \
    patch \
    # Compilers and assemblers
    gcc \
    g++ \
    clang \
    lld \
    nasm \
    yasm \
    # Version control and download tools
    git \
    curl \
    wget \
    rsync \
    # Utilities
    bash \
    coreutils \
    grep \
    sed \
    gawk \
    findutils \
    xz \
    tar \
    gzip \
    bzip2 \
    zip \
    unzip \
    # Documentation tools
    texinfo \
    # GitHub CLI for release automation
    github-cli \
    # Static libraries for common dependencies
    zlib-dev \
    zlib-static \
    openssl-dev \
    openssl-libs-static \
    linux-headers \
    # Additional useful libraries (static)
    bzip2-dev \
    bzip2-static \
    xz-dev \
    xz-static \
    ncurses-dev \
    ncurses-static

# Install Windows cross-compilers (MinGW)
RUN apk add --no-cache \
    mingw-w64-gcc

# Download and install ARM64 Linux cross-compiler
# Using bootlin toolchains (more reliable than musl.cc)
WORKDIR /opt
RUN wget -q https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--musl--stable-2024.02-1.tar.bz2 && \
    tar xjf aarch64--musl--stable-2024.02-1.tar.bz2 && \
    rm aarch64--musl--stable-2024.02-1.tar.bz2 && \
    mv aarch64--musl--stable-2024.02-1 aarch64-linux-musl

# Download and install LLVM MinGW for Windows ARM64
RUN wget -q https://github.com/mstorsjo/llvm-mingw/releases/download/20241217/llvm-mingw-20241217-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    tar xJf llvm-mingw-20241217-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    rm llvm-mingw-20241217-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    ln -s llvm-mingw-20241217-ucrt-ubuntu-20.04-x86_64 llvm-mingw

# Add all cross-compilers to PATH
ENV PATH="/opt/aarch64-linux-musl/bin:/opt/llvm-mingw/bin:${PATH}"

# Create wrapper script for easy compiler selection
RUN echo '#!/bin/sh' > /usr/local/bin/use-compiler && \
    echo 'case "$1" in' >> /usr/local/bin/use-compiler && \
    echo '  linux-amd64) export CC=gcc CXX=g++ CROSS_PREFIX= ;;' >> /usr/local/bin/use-compiler && \
    echo '  linux-arm64) export CC=aarch64-linux-gcc CXX=aarch64-linux-g++ CROSS_PREFIX=aarch64-linux- ;;' >> /usr/local/bin/use-compiler && \
    echo '  windows-amd64) export CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ CROSS_PREFIX=x86_64-w64-mingw32- ;;' >> /usr/local/bin/use-compiler && \
    echo '  windows-arm64) export CC=aarch64-w64-mingw32-gcc CXX=aarch64-w64-mingw32-g++ CROSS_PREFIX=aarch64-w64-mingw32- ;;' >> /usr/local/bin/use-compiler && \
    echo '  *) echo "Usage: use-compiler {linux-amd64|linux-arm64|windows-amd64|windows-arm64}"; exit 1 ;;' >> /usr/local/bin/use-compiler && \
    echo 'esac' >> /usr/local/bin/use-compiler && \
    chmod +x /usr/local/bin/use-compiler

# Set working directory
WORKDIR /workspace

# Verify toolchains are available and print versions
RUN echo "=== Toolchain Verification ===" && \
    echo "Alpine version: $(cat /etc/alpine-release)" && \
    echo "GCC (Linux AMD64): $(gcc --version | head -1)" && \
    echo "GCC (Linux ARM64): $(aarch64-linux-gcc --version | head -1)" && \
    echo "MinGW (Windows AMD64): $(x86_64-w64-mingw32-gcc --version | head -1)" && \
    echo "MinGW (Windows ARM64): $(aarch64-w64-mingw32-gcc --version | head -1)" && \
    echo "Clang: $(clang --version | head -1)" && \
    echo "=== All toolchains ready ==="

# Add build instructions as environment variable
ENV BUILD_INFO="Alpine-based toolchain for static binaries. Use 'use-compiler <target>' to configure."
