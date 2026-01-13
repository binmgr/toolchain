# binmgr/toolchain

[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fbinmgr%2Ftoolchain-blue)](https://ghcr.io/binmgr/toolchain)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE.md)
[![Alpine Linux](https://img.shields.io/badge/base-Alpine%20Linux-0D597F)](https://alpinelinux.org/)

**The ultimate cross-compilation toolchain for building truly static binaries across all major platforms.**

A comprehensive Docker-based development environment that enables you to build portable, zero-dependency static binaries for 16+ platforms from a single unified toolchain. Perfect for CLI tools, system utilities, embedded systems, and distributing software that "just works" everywhere.

---

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Available Targets](#-available-targets)
- [Usage](#-usage)
  - [Building for Specific Targets](#building-for-specific-targets)
  - [GitHub Actions Integration](#in-github-actions)
  - [Environment Variables](#environment-variables)
  - [Advanced Examples](#advanced-examples)
- [Included Tools & Languages](#-included-tools--languages)
- [Real-World Examples](#-real-world-examples)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [FAQ](#-faq)
- [Performance Optimization](#-performance-optimization)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

- **Alpine Linux base** with musl libc for truly portable static binaries
- **Zero dynamic dependencies** - binaries run anywhere
- **Multi-platform support**:
  - Linux AMD64 (native musl)
  - Linux ARM64 (musl cross-compile)
  - Windows AMD64 (MinGW cross-compile)
  - Windows ARM64 (LLVM MinGW cross-compile)
  - macOS AMD64 (OSXCross)
  - macOS ARM64 (OSXCross)
  - FreeBSD AMD64, ARM64 (Clang cross-compile)
  - OpenBSD AMD64, ARM64 (Clang cross-compile)
  - NetBSD AMD64, ARM64 (Clang cross-compile)
  - Android ARM64, ARMv7, x86_64, x86 (NDK r27c, API 24+)
- **Multi-architecture image**: Available for linux/amd64 and linux/arm64 runners

## 📦 Available Images

```
ghcr.io/binmgr/toolchain:latest     # Latest build
ghcr.io/binmgr/toolchain:2601       # January 2026 version (YYMM format)
ghcr.io/binmgr/toolchain:<commit>   # Specific commit SHA
```

## 🎯 Available Targets

The toolchain supports **16 compilation targets** across 6 operating system families:

| OS Family | Architectures | Compiler | Static Support |
|-----------|--------------|----------|----------------|
| **Linux** | AMD64, ARM64 | GCC (musl) | ✅ Full |
| **Windows** | AMD64, ARM64 | LLVM MinGW | ✅ Full |
| **macOS** | AMD64, ARM64 | OSXCross (Clang) | ⚠️ Partial |
| **FreeBSD** | AMD64, ARM64 | Clang | ✅ Full |
| **OpenBSD** | AMD64, ARM64 | Clang | ✅ Full |
| **NetBSD** | AMD64, ARM64 | Clang | ✅ Full |
| **Android** | ARM64, ARMv7, x86_64, x86 | NDK r27c | ⚠️ Partial |
| **WebAssembly** | wasm32, wasm64 | Emscripten | ✅ Full |

Run `docker run --rm ghcr.io/binmgr/toolchain:latest --list-targets` for detailed target information.

---

## 🚀 Quick Start

```bash
# Pull the image
docker pull ghcr.io/binmgr/toolchain:latest

# Build for your current platform
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest make

# Build for Linux ARM64
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest make

# Interactive development shell
docker run --rm -it -v $(pwd):/workspace \
  -e TARGET=windows-amd64 \
  ghcr.io/binmgr/toolchain:latest

# Show all available options
docker run --rm ghcr.io/binmgr/toolchain:latest --help
```

---

## 📚 Usage

The toolchain includes a comprehensive entrypoint script that automatically configures the build environment for your target platform.

### Quick Start

```bash
# Show help and available options
docker run --rm ghcr.io/binmgr/toolchain:latest --help

# Show toolchain version and capabilities
docker run --rm ghcr.io/binmgr/toolchain:latest --version

# List all available compilation targets
docker run --rm ghcr.io/binmgr/toolchain:latest --list-targets

# Start an interactive shell
docker run --rm -it -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest
```

### Building for Specific Targets

The easiest way to build for a specific target is to use the `TARGET` environment variable:

```bash
# Build for Linux ARM64
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest make

# Build for Windows AMD64
docker run --rm -v $(pwd):/workspace \
  -e TARGET=windows-amd64 \
  ghcr.io/binmgr/toolchain:latest make

# Build for FreeBSD ARM64
docker run --rm -v $(pwd):/workspace \
  -e TARGET=freebsd-arm64 \
  ghcr.io/binmgr/toolchain:latest ./configure --enable-static && make

# Build for Android ARM64
docker run --rm -v $(pwd):/workspace \
  -e TARGET=android-arm64 \
  ghcr.io/binmgr/toolchain:latest make
```

### In GitHub Actions

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container: ghcr.io/binmgr/toolchain:latest
    steps:
      - uses: actions/checkout@v4

      - name: Build static binary for Linux ARM64
        env:
          TARGET: linux-arm64
        run: |
          ./configure --enable-static --disable-shared
          make

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: binary-linux-arm64
          path: ./your-binary
```

### Platform-Specific Builds

```yaml
strategy:
  matrix:
    include:
      - { target: linux-amd64, cc: gcc, cxx: g++, cross_prefix: "" }
      - { target: linux-arm64, cc: aarch64-linux-gcc, cxx: aarch64-linux-g++, cross_prefix: "aarch64-linux-" }
      - { target: windows-amd64, cc: x86_64-w64-mingw32-gcc, cxx: x86_64-w64-mingw32-g++, cross_prefix: "x86_64-w64-mingw32-" }
      - { target: windows-arm64, cc: aarch64-w64-mingw32-gcc, cxx: aarch64-w64-mingw32-g++, cross_prefix: "aarch64-w64-mingw32-" }
      - { target: darwin-amd64, cc: x86_64-apple-darwin23-clang, cxx: x86_64-apple-darwin23-clang++, cross_prefix: "x86_64-apple-darwin23-" }
      - { target: darwin-arm64, cc: aarch64-apple-darwin23-clang, cxx: aarch64-apple-darwin23-clang++, cross_prefix: "aarch64-apple-darwin23-" }
      - { target: freebsd-amd64, cc: x86_64-freebsd-clang, cxx: x86_64-freebsd-clang++, cross_prefix: "x86_64-freebsd-" }
      - { target: freebsd-arm64, cc: aarch64-freebsd-clang, cxx: aarch64-freebsd-clang++, cross_prefix: "aarch64-freebsd-" }
      - { target: openbsd-amd64, cc: x86_64-openbsd-clang, cxx: x86_64-openbsd-clang++, cross_prefix: "x86_64-openbsd-" }
      - { target: openbsd-arm64, cc: aarch64-openbsd-clang, cxx: aarch64-openbsd-clang++, cross_prefix: "aarch64-openbsd-" }
      - { target: netbsd-amd64, cc: x86_64-netbsd-clang, cxx: x86_64-netbsd-clang++, cross_prefix: "x86_64-netbsd-" }
      - { target: netbsd-arm64, cc: aarch64-netbsd-clang, cxx: aarch64-netbsd-clang++, cross_prefix: "aarch64-netbsd-" }
      - { target: android-arm64, cc: aarch64-linux-android24-clang, cxx: aarch64-linux-android24-clang++, cross_prefix: "aarch64-linux-android24-" }
      - { target: android-armv7, cc: armv7a-linux-androideabi24-clang, cxx: armv7a-linux-androideabi24-clang++, cross_prefix: "armv7a-linux-androideabi24-" }
      - { target: android-x86_64, cc: x86_64-linux-android24-clang, cxx: x86_64-linux-android24-clang++, cross_prefix: "x86_64-linux-android24-" }
      - { target: android-x86, cc: i686-linux-android24-clang, cxx: i686-linux-android24-clang++, cross_prefix: "i686-linux-android24-" }

steps:
  - name: Build
    run: |
      export CC=${{ matrix.cc }}
      export CXX=${{ matrix.cxx }}
      export CROSS_PREFIX=${{ matrix.cross_prefix }}
      # Your build commands
```

### Environment Variables

The toolchain supports various environment variables for customization:

**Build Configuration:**
- `TARGET`: Specify the cross-compilation target (e.g., `linux-arm64`, `windows-amd64`, `freebsd-arm64`)
- `CC`: Override the C compiler
- `CXX`: Override the C++ compiler
- `AR`, `RANLIB`, `STRIP`: Override binary utilities
- `CFLAGS`, `CXXFLAGS`, `LDFLAGS`: Custom compiler and linker flags

**Build Optimization:**
- `USE_CCACHE`: Enable ccache (default: `1`)
- `CCACHE_DIR`: ccache directory (default: `/workspace/.ccache`)
- `PARALLEL_JOBS`: Number of parallel build jobs (default: auto-detect)

**Package Configuration:**
- `PKG_CONFIG_PATH`: pkg-config search path (auto-configured per target)
- `PKG_CONFIG_ALLOW_SYSTEM_CFLAGS`: Allow system cflags (default: `1`)
- `PKG_CONFIG_ALLOW_SYSTEM_LIBS`: Allow system libs (default: `1`)

**Example with custom configuration:**
```bash
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  -e USE_CCACHE=1 \
  -e CFLAGS="-O3 -flto" \
  -e LDFLAGS="-static -flto" \
  ghcr.io/binmgr/toolchain:latest make
```

### Local Usage

```bash
# Pull the image
docker pull ghcr.io/binmgr/toolchain:latest

# Run interactively with default environment
docker run -it -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest

# Run interactively with target pre-configured
docker run -it -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest

# Inside container - the TARGET environment automatically configures:
# CC, CXX, AR, RANLIB, STRIP, PKG_CONFIG_PATH, LDFLAGS, etc.
./configure --enable-static && make

# Alternative: Configure manually (advanced users)
export CC=aarch64-linux-gcc CXX=aarch64-linux-g++
export PKG_CONFIG_PATH=/opt/aarch64-linux-musl/aarch64-buildroot-linux-musl/sysroot/usr/lib/pkgconfig
./configure --enable-static --enable-cross-compile --host=aarch64-linux && make

# Using TARGET environment variable (recommended - automatic configuration)
docker run --rm -v $(pwd):/workspace -e TARGET=darwin-arm64 \
  ghcr.io/binmgr/toolchain:latest ./configure --enable-static && make

docker run --rm -v $(pwd):/workspace -e TARGET=freebsd-arm64 \
  ghcr.io/binmgr/toolchain:latest make

docker run --rm -v $(pwd):/workspace -e TARGET=android-arm64 \
  ghcr.io/binmgr/toolchain:latest make

# Show all available toolchains and configurations
docker run --rm ghcr.io/binmgr/toolchain:latest --info
```

### Advanced Examples

```bash
# Build with ccache and custom optimization
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  -e USE_CCACHE=1 \
  -e CFLAGS="-O3 -march=armv8-a+crypto" \
  ghcr.io/binmgr/toolchain:latest make

# Build for multiple targets in parallel (GitHub Actions)
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest bash -c '
    for target in linux-amd64 linux-arm64 windows-amd64 darwin-arm64; do
      TARGET=$target make clean all
      mv binary binary-$target
    done
  '

# Use UPX to compress the final binary
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-amd64 \
  ghcr.io/binmgr/toolchain:latest bash -c '
    make && upx --best --lzma ./your-binary
  '

# Test cross-compiled binary with QEMU
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest bash -c '
    make && qemu-aarch64 ./your-binary --version
  '
```

## Included Tools & Languages

### C/C++ Compilers & Build Tools
- **Compilers**: GCC, Clang, LLVM, MinGW (all with static library support)
- **Build systems**: Make, CMake, Meson, Ninja
- **Assemblers**: NASM, YASM
- **Utilities**: Git, wget, curl, rsync, GitHub CLI

### Modern Languages (Latest Stable)
- **Rust**: Latest stable from Alpine repos + Cargo + wasm-pack
- **Go**: Latest stable with built-in cross-compilation
- **TinyGo**: v0.34.0 (Go for embedded and WebAssembly)
- **Zig**: v0.13.0 (excellent C/C++ compiler alternative + cross-compilation)
- **Node.js**: Latest LTS + npm (for build scripts and tooling)
- **Deno**: Latest stable (modern JavaScript/TypeScript runtime)
- **Bun**: Latest stable (fast JavaScript runtime and bundler)
- **Python**: Python 3 (for build scripts)
- **Perl**: For legacy build scripts

### WebAssembly Toolchain
- **Emscripten**: C/C++ to WebAssembly compiler (emcc, em++)
- **wasm-pack**: Build Rust for WebAssembly
- **wasmtime**: Fast WebAssembly runtime

### Standard Libraries (Headers + Static Versions)

**Compression:**
- zlib, bzip2, xz, lz4, zstd

**Cryptography & SSL:**
- OpenSSL

**Terminal & UI:**
- ncurses, readline

**Parsing & Data:**
- libxml2, expat, json-c, yaml, protobuf
- pcre, pcre2, oniguruma (regex)

**Images:**
- libpng, libjpeg-turbo, giflib, libwebp, tiff

**Audio/Video Codecs:**
- opus, vorbis, ogg, lame, theora
- x264, x265, libvpx, aom, dav1d

**Fonts & Text:**
- freetype, fontconfig, fribidi, harfbuzz

**Networking:**
- curl, c-ares, nghttp2, libssh2

**Database:**
- SQLite

**Math & System:**
- GMP, MPFR, MPC, ISL
- util-linux, musl-dev, linux-headers, elfutils, libcap

**Scripting:**
- Python 3, Perl (for build scripts)

**Additional Libraries:**
- libffi, libsodium, libuv, gdbm, libedit

All libraries include both development headers and static versions where available, enabling maximum flexibility for building static binaries.

### Development & Build Tools

**Build Acceleration:**
- **ccache**: C/C++ compiler cache for faster rebuilds
- **QEMU**: User-mode emulation for testing cross-compiled binaries

**Binary Utilities:**
- **UPX**: Ultimate Packer for eXecutables (compress binaries 50-70%)
- **file**: Identify file types
- **binutils**: Binary inspection tools (readelf, objdump, strip, etc.)

**Code Analysis & Quality:**
- **clang-extra-tools**: clang-tidy, clang-format for code linting
- **valgrind**: Memory debugging and profiling
- **shellcheck**: Shell script linter

**Documentation:**
- **Doxygen**: Generate documentation from source code
- **Graphviz**: Create dependency graphs and diagrams

**Archive & Container Tools:**
- **squashfs-tools**: Create compressed filesystems
- **p7zip**: 7-Zip compression utility
- **cpio**: Archive utility

## Building the Image

```bash
# Build locally
docker build -t ghcr.io/binmgr/toolchain:latest .

# Build with all tags (YYMM and commit SHA)
YYMM=$(date +%y%m)
COMMIT=$(git rev-parse --short HEAD)

docker build -t ghcr.io/binmgr/toolchain:latest \
             -t ghcr.io/binmgr/toolchain:${YYMM} \
             -t ghcr.io/binmgr/toolchain:${COMMIT} .

# Push all tags to registry
docker push ghcr.io/binmgr/toolchain:latest
docker push ghcr.io/binmgr/toolchain:${YYMM}
docker push ghcr.io/binmgr/toolchain:${COMMIT}
```

## Toolchain Details

### Linux AMD64
- **Compiler**: GCC (musl libc)
- **Target**: x86_64-linux-musl
- **Static**: Yes (musl allows truly static binaries)

### Linux ARM64
- **Compiler**: Bootlin musl toolchain
- **Target**: aarch64-linux-musl
- **Static**: Yes (musl allows truly static binaries)

### Windows AMD64
- **Compiler**: MinGW-w64
- **Target**: x86_64-w64-mingw32
- **Static**: Yes (statically linked with MinGW runtime)

### Windows ARM64
- **Compiler**: LLVM MinGW
- **Target**: aarch64-w64-mingw32
- **Static**: Yes (statically linked)

### macOS AMD64
- **Compiler**: OSXCross (Clang)
- **Target**: x86_64-apple-darwin23
- **Static**: Partial (macOS has limitations on static linking)

### macOS ARM64 (Apple Silicon)
- **Compiler**: OSXCross (Clang)
- **Target**: aarch64-apple-darwin23
- **Static**: Partial (macOS has limitations on static linking)

### FreeBSD AMD64
- **Compiler**: Clang with FreeBSD sysroot
- **Target**: x86_64-unknown-freebsd14
- **Static**: Yes (FreeBSD supports static linking)

### FreeBSD ARM64
- **Compiler**: Clang with FreeBSD sysroot
- **Target**: aarch64-unknown-freebsd14
- **Static**: Yes (FreeBSD supports static linking)

### OpenBSD AMD64
- **Compiler**: Clang with OpenBSD sysroot
- **Target**: x86_64-unknown-openbsd
- **Static**: Yes (OpenBSD supports static linking)

### OpenBSD ARM64
- **Compiler**: Clang with OpenBSD sysroot
- **Target**: aarch64-unknown-openbsd
- **Static**: Yes (OpenBSD supports static linking)

### NetBSD AMD64
- **Compiler**: Clang with NetBSD sysroot
- **Target**: x86_64-unknown-netbsd
- **Static**: Yes (NetBSD supports static linking)

### NetBSD ARM64
- **Compiler**: Clang with NetBSD sysroot
- **Target**: aarch64-unknown-netbsd
- **Static**: Yes (NetBSD supports static linking)

### Android (All Architectures)
- **Compiler**: Android NDK r27c
- **API Level**: 24+ (Android 7.0+)
- **Targets**:
  - ARM64-v8a: aarch64-linux-android24
  - ARMv7-a: armv7a-linux-androideabi24
  - x86_64: x86_64-linux-android24
  - x86: i686-linux-android24
- **Static**: Partial (can statically link most libraries, but some Android APIs require dynamic linking)

## Image Architecture

The image is built for **linux/amd64** (x86_64) and runs on standard GitHub Actions runners and most development machines.

**Important**: The image architecture (amd64) is different from build targets. This amd64 image can cross-compile binaries FOR:
- Linux AMD64 (native)
- Linux ARM64 (cross-compile)
- Windows AMD64 (cross-compile)
- Windows ARM64 (cross-compile)
- macOS AMD64 (cross-compile)
- macOS ARM64 (cross-compile)
- FreeBSD AMD64 (cross-compile)
- FreeBSD ARM64 (cross-compile)
- OpenBSD AMD64 (cross-compile)
- OpenBSD ARM64 (cross-compile)
- NetBSD AMD64 (cross-compile)
- NetBSD ARM64 (cross-compile)
- Android ARM64-v8a (cross-compile)
- Android ARMv7-a (cross-compile)
- Android x86_64 (cross-compile)
- Android x86 (cross-compile)

## Use Cases

This image enables building static binaries for:

**C/C++ Projects:**
- Media tools: FFmpeg, ImageMagick, GraphicsMagick
- Network utilities: curl, wget, aria2
- Compression tools: 7zip, xz, zstd
- System utilities: htop, tmux, rsync
- Games and game engines

**Rust Projects:**
- CLI tools: ripgrep, fd, bat, exa
- System utilities: tokei, hyperfine
- Network tools: bandwhich, dog

**Go Projects:**
- CLI tools: hugo, caddy, minio
- DevOps tools: docker, kubectl, terraform
- Network tools: cloudflared, frp

**Zig Projects:**
- System utilities and libraries
- Can also compile C/C++ projects with better cross-compilation

**Node.js/Deno/Bun Projects:**
- Build and bundle standalone executables
- Run build scripts and tooling
- Modern JavaScript/TypeScript development

**WebAssembly Projects:**
- Compile C/C++ to WebAssembly with Emscripten
- Build Rust for WASM with wasm-pack
- TinyGo for WebAssembly targets
- Run and test WASM modules with wasmtime

All projects under the binmgr organization use this toolchain for consistent, reproducible static binary builds.

---

## 💡 Real-World Examples

### Example 1: Cross-Platform CLI Tool (Rust)

```bash
# Project structure:
# my-cli/
# ├── Cargo.toml
# ├── src/
# └── .github/workflows/release.yml

# Build for all major platforms
targets=("linux-amd64" "linux-arm64" "windows-amd64" "darwin-arm64")

for target in "${targets[@]}"; do
  docker run --rm -v $(pwd):/workspace \
    -e TARGET=$target \
    ghcr.io/binmgr/toolchain:latest \
    cargo build --release --target-dir /workspace/target-$target
done

# Compress binaries
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest \
  bash -c 'for bin in target-*/release/my-cli*; do upx --best "$bin"; done'
```

### Example 2: Static FFmpeg Build

```bash
# Clone FFmpeg
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg

# Build for Linux ARM64 with hardware acceleration
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  -e CFLAGS="-O3 -march=armv8-a+crypto+simd" \
  ghcr.io/binmgr/toolchain:latest \
  bash -c '
    ./configure \
      --enable-static \
      --disable-shared \
      --enable-gpl \
      --enable-nonfree \
      --enable-libx264 \
      --enable-libx265 \
      --enable-libopus \
      --pkg-config-flags="--static" \
      --extra-ldflags="-static" \
    && make -j$(nproc)
  '
```

### Example 3: Go Web Server for Multiple Platforms

```bash
# Build multi-platform binaries in GitHub Actions
name: Release

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target:
          - linux-amd64
          - linux-arm64
          - windows-amd64
          - freebsd-amd64
    container: ghcr.io/binmgr/toolchain:latest

    steps:
      - uses: actions/checkout@v4

      - name: Build
        env:
          TARGET: ${{ matrix.target }}
        run: |
          go build -ldflags="-s -w -extldflags '-static'" \
            -o myserver-${{ matrix.target }} .

      - name: Compress
        run: upx --best myserver-${{ matrix.target }}

      - name: Upload
        uses: actions/upload-artifact@v4
        with:
          name: myserver-${{ matrix.target }}
          path: myserver-${{ matrix.target }}
```

### Example 4: WebAssembly Build

```bash
# Build C/C++ project to WebAssembly
docker run --rm -v $(pwd):/workspace \
  -e TARGET=wasm32 \
  ghcr.io/binmgr/toolchain:latest \
  bash -c '
    emcc main.c -o main.html \
      -O3 \
      -s WASM=1 \
      -s ALLOW_MEMORY_GROWTH=1 \
      -s EXPORTED_FUNCTIONS="[_main]"
  '

# Build Rust to WebAssembly
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest \
  wasm-pack build --target web --release
```

### Example 5: Android NDK Build

```bash
# Build native library for Android
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest \
  bash -c '
    for arch in android-arm64 android-armv7 android-x86_64; do
      TARGET=$arch cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DANDROID_ABI=$(echo $arch | cut -d- -f2) \
        -B build-$arch .
      cmake --build build-$arch -- -j$(nproc)
    done
  '
```

---

## 🎯 Best Practices

### 1. Use TARGET Environment Variable

**✅ Good:**
```bash
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest make
```

**❌ Avoid:**
```bash
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest \
  bash -c 'export CC=aarch64-linux-gcc && make'
```

The `TARGET` variable automatically configures CC, CXX, PKG_CONFIG_PATH, and all necessary build variables.

### 2. Enable ccache for Faster Rebuilds

```bash
# Create persistent ccache directory
mkdir -p ~/.cache/binmgr-ccache

docker run --rm -v $(pwd):/workspace \
  -v ~/.cache/binmgr-ccache:/workspace/.ccache \
  -e TARGET=linux-arm64 \
  -e USE_CCACHE=1 \
  ghcr.io/binmgr/toolchain:latest make
```

### 3. Verify Static Linking

Always verify your binaries are truly static:

```bash
# Linux
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest \
  ldd ./your-binary
# Should output: "not a dynamic executable"

# Check dependencies
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest \
  readelf -d ./your-binary | grep NEEDED
# Should be empty
```

### 4. Optimize Binary Size

```bash
# Strip symbols and compress
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-amd64 \
  ghcr.io/binmgr/toolchain:latest \
  bash -c '
    make LDFLAGS="-s -w" &&
    strip --strip-all ./binary &&
    upx --best --lzma ./binary
  '
```

### 5. Test Cross-Compiled Binaries

```bash
# Test ARM64 binary with QEMU
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest \
  bash -c 'make && qemu-aarch64 ./binary --version'
```

### 6. Use Multi-Stage Docker Builds

```dockerfile
# Builder stage
FROM ghcr.io/binmgr/toolchain:latest AS builder
WORKDIR /build
COPY . .
ENV TARGET=linux-amd64
RUN make && strip binary && upx --best binary

# Runtime stage
FROM scratch
COPY --from=builder /build/binary /binary
ENTRYPOINT ["/binary"]
```

---

## 🔧 Troubleshooting

### Binary fails with "cannot execute: required file not found"

**Cause**: Binary is not fully static or requires specific dynamic linker.

**Solution**:
```bash
# Verify static linking
ldd ./binary  # Should say "not a dynamic executable"

# Check for dynamic dependencies
readelf -d ./binary | grep NEEDED

# Ensure static flags
export LDFLAGS="-static -static-libgcc -static-libstdc++"
```

### pkg-config can't find libraries

**Cause**: PKG_CONFIG_PATH not set correctly for cross-compilation.

**Solution**:
```bash
# Use TARGET environment variable (automatically sets PKG_CONFIG_PATH)
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest make

# Or manually set PKG_CONFIG_PATH
export PKG_CONFIG_PATH=/opt/aarch64-linux-musl/aarch64-buildroot-linux-musl/sysroot/usr/lib/pkgconfig
```

### Compilation is very slow

**Solutions**:
1. Enable ccache:
   ```bash
   -e USE_CCACHE=1 -v ~/.cache/ccache:/workspace/.ccache
   ```

2. Increase parallel jobs:
   ```bash
   -e PARALLEL_JOBS=8
   ```

3. Use host's CPU features (for native builds):
   ```bash
   -e CFLAGS="-O3 -march=native"
   ```

### macOS binary won't run: "developer cannot be verified"

**Cause**: macOS Gatekeeper security.

**Solution**:
```bash
# Sign the binary (requires Apple Developer account)
codesign -s "Developer ID" ./binary

# Or advise users to:
xattr -d com.apple.quarantine ./binary
```

### Windows binary detected as virus

**Cause**: Some antivirus software flags UPX-compressed executables.

**Solutions**:
1. Don't use UPX for Windows binaries
2. Sign binaries with a code signing certificate
3. Submit to antivirus vendors for whitelisting

---

## ❓ FAQ

### Q: Can I build Docker images inside this container?

**A**: Yes, but you need Docker-in-Docker or mount Docker socket:

```bash
docker run --rm -v $(pwd):/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/binmgr/toolchain:latest \
  docker build -t myimage .
```

### Q: How do I pass custom compiler flags?

**A**: Use CFLAGS, CXXFLAGS, and LDFLAGS environment variables:

```bash
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  -e CFLAGS="-O3 -flto -march=armv8-a" \
  -e LDFLAGS="-static -flto" \
  ghcr.io/binmgr/toolchain:latest make
```

### Q: Can I use this for kernel modules?

**A**: No, this toolchain is for userspace applications only. Kernel modules require kernel headers and specific compiler versions.

### Q: How do I build for older systems (e.g., CentOS 7)?

**A**: The musl-based static binaries work on any Linux with kernel 2.6.32+, regardless of glibc version.

### Q: Can I add custom dependencies?

**A**: Yes, extend the Dockerfile:

```dockerfile
FROM ghcr.io/binmgr/toolchain:latest
RUN apk add --no-cache my-custom-package
```

### Q: Why are my binaries larger than expected?

**A**: Static binaries include all dependencies. Solutions:
- Strip symbols: `strip --strip-all binary`
- Use link-time optimization: `LDFLAGS="-flto"`
- Compress with UPX: `upx --best binary`
- For C++, use `-fno-rtti -fno-exceptions` if not needed

### Q: How do I debug cross-compiled binaries?

**A**:
```bash
# With QEMU
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  ghcr.io/binmgr/toolchain:latest \
  qemu-aarch64 -g 1234 ./binary

# With GDB (in another terminal)
docker run --rm -v $(pwd):/workspace \
  ghcr.io/binmgr/toolchain:latest \
  gdb-multiarch -ex "target remote :1234" ./binary
```

---

## ⚡ Performance Optimization

### Compiler Optimization Flags

```bash
# Aggressive optimization (may increase binary size)
-e CFLAGS="-O3 -march=native -flto -ffast-math"
-e LDFLAGS="-flto"

# Size optimization
-e CFLAGS="-Os -ffunction-sections -fdata-sections"
-e LDFLAGS="-Wl,--gc-sections"

# Architecture-specific (ARM64 with crypto extensions)
-e CFLAGS="-O3 -march=armv8-a+crypto+simd"
```

### Build Time Optimization

```bash
# Use all CPU cores
-e PARALLEL_JOBS=$(nproc)
-e MAKEFLAGS="-j$(nproc)"

# Enable ccache with stats
docker run --rm -v $(pwd):/workspace \
  -v ~/.cache/ccache:/workspace/.ccache \
  -e USE_CCACHE=1 \
  ghcr.io/binmgr/toolchain:latest \
  bash -c 'make && ccache -s'

# Precompiled headers (C++)
-e CXXFLAGS="-fpch-preprocess"
```

### Binary Size Reduction

```bash
# Complete optimization pipeline
docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-amd64 \
  ghcr.io/binmgr/toolchain:latest \
  bash -c '
    # Build with size optimization
    make CFLAGS="-Os -ffunction-sections -fdata-sections" \
         LDFLAGS="-Wl,--gc-sections -s"

    # Strip all symbols
    strip --strip-all binary

    # Remove debug info
    strip --remove-section=.comment \
          --remove-section=.note \
          binary

    # Compress with UPX (maximum compression)
    upx --best --lzma --ultra-brute binary

    # Show final size
    ls -lh binary
  '
```

### Measuring Performance

```bash
# Build time comparison
time docker run --rm -v $(pwd):/workspace \
  -e TARGET=linux-arm64 \
  -e USE_CCACHE=0 \
  ghcr.io/binmgr/toolchain:latest make clean all

time docker run --rm -v $(pwd):/workspace \
  -v ~/.cache/ccache:/workspace/.ccache \
  -e TARGET=linux-arm64 \
  -e USE_CCACHE=1 \
  ghcr.io/binmgr/toolchain:latest make clean all
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork the repository** on GitHub
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Test your changes**: Build the Docker image and test with real projects
4. **Commit your changes**: `git commit -m 'Add amazing feature'`
5. **Push to the branch**: `git push origin feature/amazing-feature`
6. **Open a Pull Request**

### Contribution Guidelines

- Test builds for at least 3 different targets before submitting
- Update README.md if adding new tools or features
- Follow existing code style and conventions
- Ensure Docker image builds successfully
- Verify static linking works correctly

### Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include toolchain version, target platform, and reproduction steps
- Attach relevant build logs when reporting build failures

---

## 📄 License

MIT License - see [LICENSE.md](LICENSE.md) for details.

Copyright (c) 2026 binmgr

---

## 🙏 Acknowledgments

- **Alpine Linux** for the excellent musl-based distribution
- **Bootlin** for the musl cross-compilation toolchains
- **LLVM MinGW** project for Windows ARM64 support
- **OSXCross** for macOS cross-compilation
- **Android NDK** team for comprehensive mobile support
- **Emscripten** for WebAssembly compilation
- All the open-source projects that make this toolchain possible

---

## 📞 Support

- **Documentation**: [GitHub Repository](https://github.com/binmgr/toolchain)
- **Issues**: [GitHub Issues](https://github.com/binmgr/toolchain/issues)
- **Discussions**: [GitHub Discussions](https://github.com/binmgr/toolchain/discussions)

---

<div align="center">

**Built with ❤️ for developers who need truly portable binaries**

[![GitHub](https://img.shields.io/badge/GitHub-binmgr%2Ftoolchain-blue)](https://github.com/binmgr/toolchain)
[![Docker](https://img.shields.io/badge/Docker-ghcr.io%2Fbinmgr%2Ftoolchain-blue)](https://ghcr.io/binmgr/toolchain)

</div>
