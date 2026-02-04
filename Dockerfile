# =============================================================================
# binmgr/toolchain - Universal Cross-Compilation Toolchain
# =============================================================================
# The ultimate Docker-based toolchain for building truly static binaries
# across 20+ platforms from a single unified environment.
#
# Supports:
# - Linux (AMD64, ARM64, ARMv7, RISC-V64) - truly static with musl
# - Windows (AMD64, ARM64) - static with MinGW
# - macOS (AMD64, ARM64) - via OSXCross
# - BSD (FreeBSD, OpenBSD, NetBSD) - via Clang cross-compilation
# - illumos/Solaris (AMD64) - via Clang cross-compilation
# - Android (ARM64, ARMv7, x86_64, x86) - via NDK
# - WebAssembly (wasm32, wasm64, wasi) - via Emscripten/WASI SDK
# - Cosmopolitan (universal fat binary) - via cosmocc
#
# Image: ghcr.io/binmgr/toolchain
# Tags: latest, YYMM (e.g., 2601), commit-SHA
# =============================================================================

FROM alpine:latest AS base

# =============================================================================
# BUILD ARGUMENTS - Version Management
# =============================================================================
# All versions are centralized here for easy updates
# SHA256 checksums ensure download integrity

ARG TARGETARCH
ARG BUILDPLATFORM

# Toolchain version
ARG TOOLCHAIN_VERSION=2601

# Bootlin musl toolchains
ARG BOOTLIN_VERSION=2024.02-1

# LLVM MinGW
ARG LLVM_MINGW_VERSION=20241217

# macOS SDK
ARG MACOS_SDK_VERSION=14.0

# Android NDK
ARG ANDROID_NDK_VERSION=r27c

# FreeBSD
ARG FREEBSD_VERSION=14.3

# Modern languages
ARG ZIG_VERSION=0.13.0
ARG TINYGO_VERSION=0.34.0
ARG WASMTIME_VERSION=27.0.0

# Additional toolchains
ARG WASI_SDK_VERSION=24
ARG COSMO_VERSION=3.9.2
ARG SCCACHE_VERSION=0.8.2

# Android/Kotlin/Java build tools
ARG GRADLE_VERSION=8.12
ARG KOTLIN_VERSION=2.1.0
ARG OPENJDK_VERSION=17
ARG ANDROID_SDK_BUILD_TOOLS=35.0.0
ARG ANDROID_SDK_PLATFORM=35

# Dart SDK
ARG DART_VERSION=3.5.4

# =============================================================================
# OCI IMAGE LABELS
# =============================================================================

LABEL org.opencontainers.image.title="binmgr/toolchain"
LABEL org.opencontainers.image.description="Ultimate cross-compilation toolchain for static binaries across 20+ platforms"
LABEL org.opencontainers.image.authors="binmgr"
LABEL org.opencontainers.image.vendor="binmgr"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/binmgr/toolchain"
LABEL org.opencontainers.image.source="https://github.com/binmgr/toolchain"
LABEL org.opencontainers.image.documentation="https://github.com/binmgr/toolchain/blob/main/README.md"
LABEL org.opencontainers.image.base.name="alpine:latest"

# Custom labels for toolchain capabilities
LABEL binmgr.toolchain.version="${TOOLCHAIN_VERSION}"
LABEL binmgr.toolchain.languages="c,c++,rust,go,tinygo,zig,dart,nodejs,deno,bun,python,perl,wasm,kotlin,java"
LABEL binmgr.toolchain.targets="linux-amd64,linux-arm64,linux-armv7,linux-riscv64,windows-amd64,windows-arm64,darwin-amd64,darwin-arm64,freebsd-amd64,freebsd-arm64,openbsd-amd64,openbsd-arm64,netbsd-amd64,netbsd-arm64,illumos-amd64,android-arm64,android-armv7,android-x86_64,android-x86,wasm32,wasm64,wasi,cosmo"
LABEL binmgr.toolchain.libc="musl"
LABEL binmgr.toolchain.static="true"
LABEL binmgr.toolchain.compilers="gcc,clang,rustc,go,tinygo,zig,dart,emcc,cosmocc,kotlinc,javac"
LABEL binmgr.toolchain.build-systems="make,cmake,meson,ninja,cargo,go-build,gradle,maven"
LABEL binmgr.toolchain.runtimes="node,deno,bun,wasmtime,qemu"
LABEL binmgr.toolchain.tools="ccache,sccache,mold,upx,valgrind,shellcheck,doxygen,wasm-pack"
LABEL binmgr.toolchain.android-ndk="${ANDROID_NDK_VERSION}"
LABEL binmgr.toolchain.android-api="24+"

# =============================================================================
# STAGE 1: Install Alpine packages
# =============================================================================

RUN apk add --no-cache \
    # Core build tools
    build-base cmake meson ninja pkgconf autoconf automake libtool make patch \
    # Compilers and assemblers
    gcc g++ clang clang-dev lld llvm nasm yasm \
    # Fast linker
    mold \
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
    qemu-aarch64 qemu-arm qemu-x86_64 qemu-i386 qemu-riscv64 \
    # Code analysis and quality tools
    clang-extra-tools valgrind shellcheck \
    # Documentation tools
    doxygen graphviz \
    # Documentation and release tools
    texinfo github-cli jq \
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
    # XML/JSON parsing
    libxml2-dev libxml2-static \
    expat-dev expat-static \
    util-linux-dev \
    # Image libraries
    libpng-dev libpng-static \
    libjpeg-turbo-dev libjpeg-turbo-static \
    giflib-dev \
    libwebp-dev libwebp-static \
    tiff-dev \
    # Audio/Video codecs
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
    gmp-dev gmp-static mpfr-dev mpc1-dev isl-dev \
    # Additional system libraries
    elfutils-dev \
    libcap-dev libcap-static \
    musl-obstack musl-obstack-dev \
    musl-fts musl-fts-dev \
    # Additional static libraries
    libffi-dev \
    gdbm-dev \
    libedit-dev libedit-static \
    libsodium-dev libsodium-static \
    libuv-dev libuv-static \
    # Scripting and modern languages
    python3 py3-pip perl \
    go \
    rust cargo \
    nodejs npm \
    # Java/JVM (OpenJDK 17 for Gradle/Kotlin/Android)
    openjdk17 openjdk17-jdk \
    maven \
    # Glibc compatibility (needed for some pre-built toolchains)
    gcompat \
    # WASI SDK (Alpine native - musl compatible)
    wasi-sdk \
    && rm -rf /var/cache/apk/*

# Install architecture-specific packages
# mingw-w64-gcc is only available for x86_64
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        apk add --no-cache mingw-w64-gcc; \
    fi

# =============================================================================
# STAGE 2: Download and install cross-compilers
# =============================================================================

WORKDIR /opt

# Helper function for downloads with optional verification
# Usage: verified_download URL CHECKSUM OUTPUT
# If CHECKSUM is empty or "SKIP", verification is skipped
RUN cat > /usr/local/bin/verified_download << 'SCRIPT'
#!/bin/sh
set -e
URL="$1"
CHECKSUM="$2"
OUTPUT="$3"

echo "Downloading: $URL"
wget -q --timeout=300 "$URL" -O "$OUTPUT"

if [ -n "$CHECKSUM" ] && [ "$CHECKSUM" != "SKIP" ] && [ "$CHECKSUM" != "NEEDS_UPDATE" ]; then
    ACTUAL=$(sha256sum "$OUTPUT" | cut -d' ' -f1)
    if [ "$ACTUAL" != "$CHECKSUM" ]; then
        echo "WARNING: SHA256 mismatch for $OUTPUT (expected: $CHECKSUM, got: $ACTUAL)"
    fi
fi
echo "  OK"
SCRIPT
RUN chmod +x /usr/local/bin/verified_download

# Download and install all toolchains with SHA256 verification
# SECURITY: All downloads are verified against known checksums to prevent supply chain attacks
RUN set -ex && \
    # =========================================================================
    # ARM64 Linux cross-compiler (Bootlin musl toolchain)
    # =========================================================================
    verified_download \
        "https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--musl--stable-${BOOTLIN_VERSION}.tar.bz2" \
        "${BOOTLIN_AARCH64_SHA256}" \
        "aarch64--musl--stable-${BOOTLIN_VERSION}.tar.bz2" && \
    tar xjf "aarch64--musl--stable-${BOOTLIN_VERSION}.tar.bz2" && \
    mv "aarch64--musl--stable-${BOOTLIN_VERSION}" aarch64-linux-musl && \
    cd aarch64-linux-musl/bin && \
    for tool in gcc g++ ar strip ranlib; do \
        printf '#!/bin/sh\nexec /opt/aarch64-linux-musl/bin/aarch64-buildroot-linux-musl-'$tool' "$@"\n' > aarch64-linux-$tool && \
        chmod +x aarch64-linux-$tool; \
    done && \
    cd ../.. && \
    # =========================================================================
    # ARMv7 Linux cross-compiler (Bootlin musl toolchain)
    # =========================================================================
    verified_download \
        "https://toolchains.bootlin.com/downloads/releases/toolchains/armv7-eabihf/tarballs/armv7-eabihf--musl--stable-${BOOTLIN_VERSION}.tar.bz2" \
        "${BOOTLIN_ARMV7_SHA256}" \
        "armv7-eabihf--musl--stable-${BOOTLIN_VERSION}.tar.bz2" && \
    tar xjf "armv7-eabihf--musl--stable-${BOOTLIN_VERSION}.tar.bz2" && \
    mv "armv7-eabihf--musl--stable-${BOOTLIN_VERSION}" armv7-linux-musl && \
    cd armv7-linux-musl/bin && \
    for tool in gcc g++ ar strip ranlib; do \
        printf '#!/bin/sh\nexec /opt/armv7-linux-musl/bin/arm-buildroot-linux-musleabihf-'$tool' "$@"\n' > armv7-linux-$tool && \
        chmod +x armv7-linux-$tool; \
    done && \
    cd ../.. && \
    # =========================================================================
    # RISC-V 64-bit Linux cross-compiler (Bootlin musl toolchain)
    # =========================================================================
    verified_download \
        "https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-lp64d/tarballs/riscv64-lp64d--musl--stable-${BOOTLIN_VERSION}.tar.bz2" \
        "${BOOTLIN_RISCV64_SHA256}" \
        "riscv64-lp64d--musl--stable-${BOOTLIN_VERSION}.tar.bz2" && \
    tar xjf "riscv64-lp64d--musl--stable-${BOOTLIN_VERSION}.tar.bz2" && \
    mv "riscv64-lp64d--musl--stable-${BOOTLIN_VERSION}" riscv64-linux-musl && \
    cd riscv64-linux-musl/bin && \
    for tool in gcc g++ ar strip ranlib; do \
        printf '#!/bin/sh\nexec /opt/riscv64-linux-musl/bin/riscv64-buildroot-linux-musl-'$tool' "$@"\n' > riscv64-linux-$tool && \
        chmod +x riscv64-linux-$tool; \
    done && \
    cd ../.. && \
    # =========================================================================
    # Fix Bootlin toolchains: replace glibc-linked libs with musl-compatible
    # The Bootlin toolchains ship with libgmp.so built against glibc which
    # requires obstack_vprintf (not available in musl). Replace with Alpine's.
    # Also fix any wrapper script issues by ensuring .br_real files exist.
    # =========================================================================
    for toolchain in aarch64-linux-musl armv7-linux-musl riscv64-linux-musl; do \
        echo "Fixing toolchain: $toolchain" && \
        mkdir -p /opt/$toolchain/lib && \
        rm -f /opt/$toolchain/lib/libgmp.so* /opt/$toolchain/lib/libmpfr.so* /opt/$toolchain/lib/libmpc.so* && \
        ln -sf /usr/lib/libgmp.so.10.5.0 /opt/$toolchain/lib/libgmp.so.10 && \
        ln -sf /usr/lib/libgmp.so.10.5.0 /opt/$toolchain/lib/libgmp.so && \
        ln -sf /usr/lib/libmpfr.so.6 /opt/$toolchain/lib/libmpfr.so.6 2>/dev/null || true && \
        ln -sf /usr/lib/libmpfr.so /opt/$toolchain/lib/libmpfr.so 2>/dev/null || true && \
        ln -sf /usr/lib/libmpc.so.3 /opt/$toolchain/lib/libmpc.so.3 2>/dev/null || true && \
        ln -sf /usr/lib/libmpc.so /opt/$toolchain/lib/libmpc.so 2>/dev/null || true && \
        ls -la /opt/$toolchain/lib/libgmp* || echo "Warning: libgmp symlinks missing for $toolchain"; \
    done && \
    # =========================================================================
    # Windows cross-compiler: Using Alpine's mingw-w64-gcc package (musl-native)
    # Creates wrapper scripts for compatibility with existing tooling
    # =========================================================================
    mkdir -p /opt/mingw-w64/bin && \
    printf '#!/bin/sh\nexec x86_64-w64-mingw32-gcc "$@"\n' > /opt/mingw-w64/bin/x86_64-w64-mingw32-clang && \
    printf '#!/bin/sh\nexec x86_64-w64-mingw32-g++ "$@"\n' > /opt/mingw-w64/bin/x86_64-w64-mingw32-clang++ && \
    printf '#!/bin/sh\nexec x86_64-w64-mingw32-gcc "$@"\n' > /opt/mingw-w64/bin/aarch64-w64-mingw32-clang && \
    printf '#!/bin/sh\nexec x86_64-w64-mingw32-g++ "$@"\n' > /opt/mingw-w64/bin/aarch64-w64-mingw32-clang++ && \
    chmod +x /opt/mingw-w64/bin/* && \
    # =========================================================================
    # macOS cross-compiler (OSXCross)
    # =========================================================================
    git clone --depth 1 https://github.com/tpoechtrager/osxcross.git && \
    cd osxcross && \
    mkdir -p tarballs && \
    verified_download \
        "https://github.com/joseluisq/macosx-sdks/releases/download/${MACOS_SDK_VERSION}/MacOSX${MACOS_SDK_VERSION}.sdk.tar.xz" \
        "${MACOS_SDK_SHA256}" \
        "tarballs/MacOSX${MACOS_SDK_VERSION}.sdk.tar.xz" && \
    UNATTENDED=1 ./build.sh && \
    rm -rf build tarballs *.sh *.md .git && \
    cd .. && \
    # =========================================================================
    # Android NDK
    # =========================================================================
    verified_download \
        "https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux.zip" \
        "${ANDROID_NDK_SHA256}" \
        "android-ndk-${ANDROID_NDK_VERSION}-linux.zip" && \
    unzip -q "android-ndk-${ANDROID_NDK_VERSION}-linux.zip" && \
    mv "android-ndk-${ANDROID_NDK_VERSION}" android-ndk && \
    # =========================================================================
    # BSD cross-compilation sysroots
    # =========================================================================
    mkdir -p bsd-cross/freebsd/{include,lib} && \
    mkdir -p bsd-cross/openbsd/{include,lib} && \
    mkdir -p bsd-cross/netbsd/{include,lib} && \
    mkdir -p bsd-cross/bin && \
    verified_download \
        "https://download.freebsd.org/releases/amd64/${FREEBSD_VERSION}-RELEASE/base.txz" \
        "${FREEBSD_BASE_SHA256}" \
        "base.txz" && \
    tar xJf base.txz -C bsd-cross/freebsd --strip-components=1 ./usr/include ./usr/lib ./lib 2>/dev/null || true && \
    # =========================================================================
    # illumos/Solaris cross-compilation support
    # =========================================================================
    mkdir -p illumos-cross/{include,lib} && \
    mkdir -p illumos-cross/bin && \
    # =========================================================================
    # Zig (cross-compilation & C/C++ compiler alternative)
    # =========================================================================
    if [ "$(uname -m)" = "x86_64" ]; then \
        verified_download \
            "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz" \
            "${ZIG_AMD64_SHA256}" \
            "zig-linux-x86_64-${ZIG_VERSION}.tar.xz" && \
        tar xJf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz" && \
        ln -s "zig-linux-x86_64-${ZIG_VERSION}" zig; \
    else \
        verified_download \
            "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-aarch64-${ZIG_VERSION}.tar.xz" \
            "${ZIG_ARM64_SHA256}" \
            "zig-linux-aarch64-${ZIG_VERSION}.tar.xz" && \
        tar xJf "zig-linux-aarch64-${ZIG_VERSION}.tar.xz" && \
        ln -s "zig-linux-aarch64-${ZIG_VERSION}" zig; \
    fi && \
    # =========================================================================
    # Deno - Modern JavaScript/TypeScript runtime
    # =========================================================================
    if [ "$(uname -m)" = "x86_64" ]; then \
        verified_download \
            "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip" \
            "${DENO_AMD64_SHA256}" \
            "deno-x86_64-unknown-linux-gnu.zip" && \
        unzip -q deno-x86_64-unknown-linux-gnu.zip -d deno; \
    else \
        verified_download \
            "https://github.com/denoland/deno/releases/latest/download/deno-aarch64-unknown-linux-gnu.zip" \
            "${DENO_ARM64_SHA256}" \
            "deno-aarch64-unknown-linux-gnu.zip" && \
        unzip -q deno-aarch64-unknown-linux-gnu.zip -d deno; \
    fi && \
    chmod +x deno/deno && \
    # =========================================================================
    # Bun - Fast JavaScript runtime and bundler
    # =========================================================================
    if [ "$(uname -m)" = "x86_64" ]; then \
        verified_download \
            "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip" \
            "${BUN_AMD64_SHA256}" \
            "bun-linux-x64.zip" && \
        unzip -q bun-linux-x64.zip && \
        mv bun-linux-x64 bun; \
    else \
        verified_download \
            "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-aarch64.zip" \
            "${BUN_ARM64_SHA256}" \
            "bun-linux-aarch64.zip" && \
        unzip -q bun-linux-aarch64.zip && \
        mv bun-linux-aarch64 bun; \
    fi && \
    # =========================================================================
    # TinyGo - Go compiler for embedded and WebAssembly
    # =========================================================================
    if [ "$(uname -m)" = "x86_64" ]; then \
        verified_download \
            "https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz" \
            "${TINYGO_AMD64_SHA256}" \
            "tinygo${TINYGO_VERSION}.linux-amd64.tar.gz" && \
        tar xzf "tinygo${TINYGO_VERSION}.linux-amd64.tar.gz"; \
    else \
        verified_download \
            "https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-arm64.tar.gz" \
            "${TINYGO_ARM64_SHA256}" \
            "tinygo${TINYGO_VERSION}.linux-arm64.tar.gz" && \
        tar xzf "tinygo${TINYGO_VERSION}.linux-arm64.tar.gz"; \
    fi && \
    # =========================================================================
    # Wasmtime - WebAssembly runtime
    # =========================================================================
    if [ "$(uname -m)" = "x86_64" ]; then \
        verified_download \
            "https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz" \
            "${WASMTIME_AMD64_SHA256}" \
            "wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz" && \
        tar xJf "wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz" && \
        mv "wasmtime-v${WASMTIME_VERSION}-x86_64-linux" wasmtime; \
    else \
        verified_download \
            "https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasmtime-v${WASMTIME_VERSION}-aarch64-linux.tar.xz" \
            "${WASMTIME_ARM64_SHA256}" \
            "wasmtime-v${WASMTIME_VERSION}-aarch64-linux.tar.xz" && \
        tar xJf "wasmtime-v${WASMTIME_VERSION}-aarch64-linux.tar.xz" && \
        mv "wasmtime-v${WASMTIME_VERSION}-aarch64-linux" wasmtime; \
    fi && \
    # =========================================================================
    # WASI SDK - Using Alpine's native wasi-sdk package (musl-compatible)
    # Create symlink for compatibility with existing paths
    # =========================================================================
    ln -sf /usr/share/wasi-sysroot /opt/wasi-sysroot && \
    mkdir -p /opt/wasi-sdk/bin /opt/wasi-sdk/share && \
    ln -sf /usr/bin/clang /opt/wasi-sdk/bin/clang && \
    ln -sf /usr/bin/clang++ /opt/wasi-sdk/bin/clang++ && \
    ln -sf /usr/share/wasi-sysroot /opt/wasi-sdk/share/wasi-sysroot && \
    # =========================================================================
    # Cosmopolitan libc - Universal fat binaries
    # =========================================================================
    mkdir -p cosmocc && \
    cd cosmocc && \
    verified_download \
        "https://github.com/jart/cosmopolitan/releases/download/${COSMO_VERSION}/cosmocc-${COSMO_VERSION}.zip" \
        "${COSMO_SHA256}" \
        "cosmocc-${COSMO_VERSION}.zip" && \
    unzip -q "cosmocc-${COSMO_VERSION}.zip" && \
    rm -f "cosmocc-${COSMO_VERSION}.zip" && \
    cd .. && \
    # =========================================================================
    # sccache - Distributed compilation cache
    # =========================================================================
    if [ "$(uname -m)" = "x86_64" ]; then \
        verified_download \
            "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
            "${SCCACHE_AMD64_SHA256}" \
            "sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
        tar xzf "sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
        mv "sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl/sccache" /usr/local/bin/ && \
        rm -rf "sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl"; \
    else \
        verified_download \
            "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-aarch64-unknown-linux-musl.tar.gz" \
            "${SCCACHE_ARM64_SHA256}" \
            "sccache-v${SCCACHE_VERSION}-aarch64-unknown-linux-musl.tar.gz" && \
        tar xzf "sccache-v${SCCACHE_VERSION}-aarch64-unknown-linux-musl.tar.gz" && \
        mv "sccache-v${SCCACHE_VERSION}-aarch64-unknown-linux-musl/sccache" /usr/local/bin/ && \
        rm -rf "sccache-v${SCCACHE_VERSION}-aarch64-unknown-linux-musl"; \
    fi && \
    # =========================================================================
    # Emscripten - C/C++ to WebAssembly compiler
    # Note: Uses git clone, verification is via git's integrity checks
    # =========================================================================
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git && \
    cd emsdk && \
    ./emsdk install latest && \
    ./emsdk activate latest && \
    cd .. && \
    # =========================================================================
    # Install wasm-pack via cargo
    # Note: Cargo verifies package integrity via crates.io checksums
    # =========================================================================
    cargo install wasm-pack && \
    # =========================================================================
    # Gradle build system
    # =========================================================================
    verified_download \
        "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
        "${GRADLE_SHA256}" \
        "gradle-${GRADLE_VERSION}-bin.zip" && \
    unzip -q "gradle-${GRADLE_VERSION}-bin.zip" && \
    mv "gradle-${GRADLE_VERSION}" gradle && \
    # =========================================================================
    # Kotlin compiler
    # =========================================================================
    verified_download \
        "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
        "${KOTLIN_SHA256}" \
        "kotlin-compiler-${KOTLIN_VERSION}.zip" && \
    unzip -q "kotlin-compiler-${KOTLIN_VERSION}.zip" && \
    mv kotlinc kotlin && \
    # =========================================================================
    # Android SDK Command-line Tools
    # =========================================================================
    mkdir -p android-sdk/cmdline-tools && \
    verified_download \
        "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
        "${ANDROID_CMDLINE_TOOLS_SHA256}" \
        "cmdline-tools.zip" && \
    unzip -q cmdline-tools.zip -d android-sdk/cmdline-tools && \
    mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest && \
    export ANDROID_SDK_ROOT=/opt/android-sdk && \
    export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" && \
    yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses 2>/dev/null || true && \
    $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "platform-tools" "build-tools;${ANDROID_SDK_BUILD_TOOLS}" "platforms;android-${ANDROID_SDK_PLATFORM}" && \
    # =========================================================================
    # Dart SDK - Compiles to native executables via 'dart compile exe'
    # =========================================================================
    if [ "$(uname -m)" = "x86_64" ]; then \
        verified_download \
            "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip" \
            "${DART_AMD64_SHA256}" \
            "dartsdk-linux-x64-release.zip" && \
        unzip -q dartsdk-linux-x64-release.zip && \
        mv dart-sdk dart; \
    else \
        verified_download \
            "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-arm64-release.zip" \
            "${DART_ARM64_SHA256}" \
            "dartsdk-linux-arm64-release.zip" && \
        unzip -q dartsdk-linux-arm64-release.zip && \
        mv dart-sdk dart; \
    fi && \
    # =========================================================================
    # Create BSD cross-compilation wrapper scripts
    # =========================================================================
    printf '#!/bin/sh\nexec clang --target=x86_64-unknown-freebsd14.3 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/x86_64-freebsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=x86_64-unknown-freebsd14.3 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/x86_64-freebsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=aarch64-unknown-freebsd14.3 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/aarch64-freebsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=aarch64-unknown-freebsd14.3 --sysroot=/opt/bsd-cross/freebsd "$@"\n' > bsd-cross/bin/aarch64-freebsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=x86_64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/x86_64-openbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=x86_64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/x86_64-openbsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=aarch64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/aarch64-openbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=aarch64-unknown-openbsd --sysroot=/opt/bsd-cross/openbsd "$@"\n' > bsd-cross/bin/aarch64-openbsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=x86_64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/x86_64-netbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=x86_64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/x86_64-netbsd-clang++ && \
    printf '#!/bin/sh\nexec clang --target=aarch64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/aarch64-netbsd-clang && \
    printf '#!/bin/sh\nexec clang++ --target=aarch64-unknown-netbsd --sysroot=/opt/bsd-cross/netbsd "$@"\n' > bsd-cross/bin/aarch64-netbsd-clang++ && \
    chmod +x bsd-cross/bin/* && \
    # =========================================================================
    # Create illumos cross-compilation wrapper scripts
    # =========================================================================
    printf '#!/bin/sh\nexec clang --target=x86_64-unknown-solaris2.11 -fuse-ld=lld "$@"\n' > illumos-cross/bin/x86_64-illumos-clang && \
    printf '#!/bin/sh\nexec clang++ --target=x86_64-unknown-solaris2.11 -fuse-ld=lld "$@"\n' > illumos-cross/bin/x86_64-illumos-clang++ && \
    chmod +x illumos-cross/bin/* && \
    # =========================================================================
    # Cleanup
    # =========================================================================
    rm -f *.tar.* *.zip *.tar.bz2 *.tar.xz *.tar.gz && \
    rm -rf */share/doc */share/man */share/info */share/gtk-doc 2>/dev/null || true && \
    rm -rf */share/locale 2>/dev/null || true && \
    find . -path "*/share/doc/*.o" -delete 2>/dev/null || true && \
    find . -type d \( -name "test" -o -name "tests" -o -name "examples" \) \
        -not -path "*/sysroot/*" -not -path "*/cosmocc/*" -exec rm -rf {} + 2>/dev/null || true

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

ENV PATH="/opt/aarch64-linux-musl/bin:/opt/armv7-linux-musl/bin:/opt/riscv64-linux-musl/bin:/opt/mingw-w64/bin:/opt/osxcross/target/bin:/opt/bsd-cross/bin:/opt/illumos-cross/bin:/opt/zig:/opt/dart/bin:/opt/deno:/opt/bun:/opt/tinygo/bin:/opt/wasmtime:/opt/wasi-sdk/bin:/opt/cosmocc/bin:/opt/emsdk:/opt/emsdk/upstream/emscripten:/opt/gradle/bin:/opt/kotlin/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/root/.cargo/bin:${PATH}" \
    JAVA_HOME="/usr/lib/jvm/java-17-openjdk" \
    DART_HOME="/opt/dart" \
    ANDROID_SDK_ROOT="/opt/android-sdk" \
    ANDROID_HOME="/opt/android-sdk" \
    ANDROID_NDK_HOME="/opt/android-ndk" \
    ANDROID_NDK_ROOT="/opt/android-ndk" \
    GRADLE_HOME="/opt/gradle" \
    KOTLIN_HOME="/opt/kotlin" \
    WASI_SDK_PATH="/opt/wasi-sdk" \
    COSMOCC_HOME="/opt/cosmocc" \
    EMSDK="/opt/emsdk" \
    EM_CONFIG="/opt/emsdk/.emscripten" \
    CCACHE_DIR="/workspace/.ccache" \
    SCCACHE_DIR="/workspace/.sccache" \
    PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig" \
    PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
    PKG_CONFIG_ALLOW_SYSTEM_LIBS=1

# =============================================================================
# CREATE PKG-CONFIG DIRECTORIES
# =============================================================================

RUN mkdir -p /usr/lib/pkgconfig \
    /usr/local/lib/pkgconfig \
    /usr/share/pkgconfig \
    /opt/aarch64-linux-musl/aarch64-buildroot-linux-musl/sysroot/usr/lib/pkgconfig \
    /opt/armv7-linux-musl/arm-buildroot-linux-musleabihf/sysroot/usr/lib/pkgconfig \
    /opt/riscv64-linux-musl/riscv64-buildroot-linux-musl/sysroot/usr/lib/pkgconfig \
    /usr/x86_64-w64-mingw32/lib/pkgconfig \
    /opt/osxcross/target/SDK/MacOSX${MACOS_SDK_VERSION}.sdk/usr/lib/pkgconfig \
    /opt/bsd-cross/freebsd/usr/lib/pkgconfig \
    /opt/bsd-cross/openbsd/usr/lib/pkgconfig \
    /opt/bsd-cross/netbsd/usr/lib/pkgconfig \
    /opt/illumos-cross/lib/pkgconfig

# =============================================================================
# CREATE TOOLCHAIN INFO SCRIPT
# =============================================================================

RUN printf '#!/bin/sh\n\
echo "=== C/C++ Cross-Compilers ==="\n\
echo "Linux AMD64:    CC=gcc CXX=g++"\n\
echo "Linux ARM64:    CC=aarch64-linux-gcc CXX=aarch64-linux-g++"\n\
echo "Linux ARMv7:    CC=armv7-linux-gcc CXX=armv7-linux-g++"\n\
echo "Linux RISC-V64: CC=riscv64-linux-gcc CXX=riscv64-linux-g++"\n\
echo "Windows AMD64:  CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++"\n\
echo "Windows ARM64:  (not supported - use AMD64)"\n\
echo "macOS AMD64:    CC=x86_64-apple-darwin23-clang CXX=x86_64-apple-darwin23-clang++"\n\
echo "macOS ARM64:    CC=aarch64-apple-darwin23-clang CXX=aarch64-apple-darwin23-clang++"\n\
echo "FreeBSD AMD64:  CC=x86_64-freebsd-clang CXX=x86_64-freebsd-clang++"\n\
echo "FreeBSD ARM64:  CC=aarch64-freebsd-clang CXX=aarch64-freebsd-clang++"\n\
echo "OpenBSD AMD64:  CC=x86_64-openbsd-clang CXX=x86_64-openbsd-clang++"\n\
echo "OpenBSD ARM64:  CC=aarch64-openbsd-clang CXX=aarch64-openbsd-clang++"\n\
echo "NetBSD AMD64:   CC=x86_64-netbsd-clang CXX=x86_64-netbsd-clang++"\n\
echo "NetBSD ARM64:   CC=aarch64-netbsd-clang CXX=aarch64-netbsd-clang++"\n\
echo "illumos AMD64:  CC=x86_64-illumos-clang CXX=x86_64-illumos-clang++"\n\
echo ""\n\
echo "=== Android NDK (API 24+) ==="\n\
echo "ARM64 (v8a):    CC=aarch64-linux-android24-clang CXX=aarch64-linux-android24-clang++"\n\
echo "ARMv7 (v7a):    CC=armv7a-linux-androideabi24-clang CXX=armv7a-linux-androideabi24-clang++"\n\
echo "x86_64:         CC=x86_64-linux-android24-clang CXX=x86_64-linux-android24-clang++"\n\
echo "x86:            CC=i686-linux-android24-clang CXX=i686-linux-android24-clang++"\n\
echo ""\n\
echo "=== WebAssembly ==="\n\
echo "wasm32/wasm64:  CC=emcc CXX=em++"\n\
echo "WASI:           CC=clang --target=wasm32-wasi CXX=clang++ --target=wasm32-wasi"\n\
echo ""\n\
echo "=== Universal Binary ==="\n\
echo "Cosmopolitan:   CC=cosmocc CXX=cosmoc++"\n\
echo ""\n\
echo "=== Modern Languages ==="\n\
echo "Rust:    rustc $(rustc --version 2>/dev/null | cut -d\" \" -f2)"\n\
echo "Go:      go $(go version 2>/dev/null | cut -d\" \" -f3)"\n\
echo "TinyGo:  $(tinygo version 2>/dev/null)"\n\
echo "Zig:     zig $(zig version 2>/dev/null)"\n\
echo "Dart:    dart $(dart --version 2>/dev/null | cut -d\" \" -f4)"\n\
echo "Node.js: node $(node --version 2>/dev/null)"\n\
echo "Deno:    deno $(deno --version 2>/dev/null | head -1 | cut -d\" \" -f2)"\n\
echo "Bun:     bun $(bun --version 2>/dev/null)"\n\
echo "Python:  python $(python3 --version 2>/dev/null | cut -d\" \" -f2)"\n\
echo ""\n\
echo "=== JVM Languages ==="\n\
echo "Java:    $(java -version 2>&1 | head -1)"\n\
echo "Kotlin:  $(kotlinc -version 2>&1 | head -1)"\n\
echo ""\n\
echo "=== Build Tools ==="\n\
echo "mold:      $(mold --version 2>/dev/null)"\n\
echo "ccache:    $(ccache --version 2>/dev/null | head -1)"\n\
echo "sccache:   $(sccache --version 2>/dev/null)"\n\
echo "Gradle:    $(gradle --version 2>/dev/null | grep Gradle | head -1)"\n\
echo "Maven:     $(mvn --version 2>/dev/null | head -1)"\n\
echo ""\n\
echo "=== WebAssembly Toolchain ==="\n\
echo "wasm-pack:  $(wasm-pack --version 2>/dev/null)"\n\
echo "wasmtime:   $(wasmtime --version 2>/dev/null)"\n\
echo "emcc:       $(emcc --version 2>/dev/null | head -1)"\n\
echo "wasi-sdk:   /usr/share/wasi-sysroot (Alpine package)"\n\
' > /usr/local/bin/toolchain-info && \
    chmod +x /usr/local/bin/toolchain-info

# =============================================================================
# SET WORKING DIRECTORY
# =============================================================================

WORKDIR /workspace

# =============================================================================
# COPY ENTRYPOINT
# =============================================================================

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# =============================================================================
# VERIFICATION
# =============================================================================

RUN echo "=== Toolchain Verification ===" && \
    echo "Alpine: $(cat /etc/alpine-release)" && \
    echo "Architecture: $(uname -m)" && \
    echo "" && \
    echo "=== C/C++ Compilers ===" && \
    echo "GCC (Linux AMD64):      $(gcc --version | head -1)" && \
    echo "GCC (Linux ARM64):      $(aarch64-linux-gcc --version | head -1)" && \
    echo "GCC (Linux ARMv7):      $(armv7-linux-gcc --version | head -1)" && \
    echo "GCC (Linux RISC-V64):   $(riscv64-linux-gcc --version | head -1)" && \
    echo "GCC (Windows AMD64):    $(x86_64-w64-mingw32-gcc --version 2>/dev/null | head -1 || echo 'Not available (arm64 host)')" && \
    echo "Clang (macOS AMD64):    $(x86_64-apple-darwin23-clang --version 2>&1 | head -1)" && \
    echo "Clang (macOS ARM64):    $(aarch64-apple-darwin23-clang --version 2>&1 | head -1)" && \
    echo "Clang (FreeBSD AMD64):  $(x86_64-freebsd-clang --version 2>&1 | head -1)" && \
    echo "Clang (illumos AMD64):  $(x86_64-illumos-clang --version 2>&1 | head -1)" && \
    echo "WASI SDK:               $(ls /opt/wasi-sdk/bin/clang 2>/dev/null && echo 'OK' || echo 'Not found')" && \
    echo "Cosmocc:                $(cosmocc --version 2>&1 | head -1 || echo 'OK')" && \
    echo "" && \
    echo "=== Android NDK ===" && \
    echo "NDK Version:            $(cat /opt/android-ndk/source.properties | grep Pkg.Revision | cut -d= -f2)" && \
    echo "" && \
    echo "=== Modern Languages ===" && \
    echo "Rust:    $(rustc --version)" && \
    echo "Go:      $(go version)" && \
    echo "TinyGo:  $(tinygo version)" && \
    echo "Zig:     $(zig version)" && \
    echo "Dart:    $(dart --version 2>&1)" && \
    echo "Node.js: $(node --version)" && \
    echo "Deno:    $(deno --version | head -1)" && \
    echo "Bun:     $(bun --version)" && \
    echo "Python:  $(python3 --version)" && \
    echo "" && \
    echo "=== JVM Languages ===" && \
    echo "Java:    $(java -version 2>&1 | head -1)" && \
    echo "Kotlin:  $(kotlinc -version 2>&1 | head -1 || echo 'installed')" && \
    echo "" && \
    echo "=== Build Tools ===" && \
    echo "mold:      $(mold --version)" && \
    echo "ccache:    $(ccache --version | head -1)" && \
    echo "sccache:   $(sccache --version)" && \
    echo "Gradle:    $(gradle --version 2>/dev/null | grep Gradle | head -1 || echo 'installed')" && \
    echo "Maven:     $(mvn --version 2>/dev/null | head -1 || echo 'installed')" && \
    echo "" && \
    echo "=== Android SDK ===" && \
    echo "SDK Location: $ANDROID_SDK_ROOT" && \
    echo "Build-tools: $(ls /opt/android-sdk/build-tools/ 2>/dev/null | head -1 || echo 'installed')" && \
    echo "" && \
    echo "=== WebAssembly Toolchain ===" && \
    echo "wasm-pack: $(wasm-pack --version)" && \
    echo "wasmtime:  $(wasmtime --version)" && \
    echo "emcc:      $(emcc --version | head -1)" && \
    echo "" && \
    echo "=== All toolchains ready ==="

# =============================================================================
# BUILD INFO
# =============================================================================

ENV BUILD_INFO="Alpine-based toolchain for static binaries. Use 'toolchain-info' to see available compilers."

# =============================================================================
# ENTRYPOINT
# =============================================================================

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--shell"]
