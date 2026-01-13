# binmgr/toolchain

General-purpose Docker image for building truly static binaries across multiple platforms.

## Features

- **Alpine Linux base** with musl libc for truly portable static binaries
- **Zero dynamic dependencies** - binaries run anywhere
- **Multi-platform support**:
  - Linux AMD64 (native musl)
  - Linux ARM64 (musl cross-compile)
  - Windows AMD64 (MinGW cross-compile)
  - Windows ARM64 (LLVM MinGW cross-compile)
  - macOS AMD64 (OSXCross)
  - macOS ARM64 (OSXCross)
- **Multi-architecture image**: Available for linux/amd64 and linux/arm64 runners

## Available Images

```
ghcr.io/binmgr/toolchain:latest     # Latest build
ghcr.io/binmgr/toolchain:2601       # January 2026 version (YYMM format)
ghcr.io/binmgr/toolchain:<commit>   # Specific commit SHA
```

## Usage

### In GitHub Actions

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container: ghcr.io/binmgr/toolchain:latest
    steps:
      - name: Build static binary
        run: |
          # Configure for your target platform
          export CC=gcc
          export CXX=g++

          # Build your project (example)
          ./configure --enable-static --disable-shared
          make
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

steps:
  - name: Build
    run: |
      export CC=${{ matrix.cc }}
      export CXX=${{ matrix.cxx }}
      export CROSS_PREFIX=${{ matrix.cross_prefix }}
      # Your build commands
```

### Local Usage

```bash
# Pull the image
docker pull ghcr.io/binmgr/toolchain:latest

# Run interactively
docker run -it -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest

# Inside container - Build for Linux AMD64 (native)
export CC=gcc CXX=g++
./configure --enable-static && make

# Build for Linux ARM64 (cross-compile)
export CC=aarch64-linux-gcc CXX=aarch64-linux-g++
./configure --enable-static --enable-cross-compile --host=aarch64-linux && make

# Build for Windows AMD64 (cross-compile)
export CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++
./configure --enable-static --enable-cross-compile --host=x86_64-w64-mingw32 && make

# Build for macOS ARM64 (cross-compile)
export CC=aarch64-apple-darwin23-clang CXX=aarch64-apple-darwin23-clang++
./configure --enable-static --enable-cross-compile --host=aarch64-apple-darwin23 && make

# Show all available toolchains
toolchain-info
```

## Included Tools & Libraries

### Compilers & Build Tools
- **Compilers**: GCC, Clang, MinGW (all with static library support)
- **Build systems**: Make, CMake, Meson, Ninja
- **Assemblers**: NASM, YASM
- **Utilities**: Git, wget, curl, rsync, GitHub CLI

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

All libraries include both development headers and static versions where available, enabling maximum flexibility for building static binaries.

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

## Image Architecture Support

The image itself is built for both:
- `linux/amd64` - For x86_64 GitHub Actions runners
- `linux/arm64` - For ARM64 GitHub Actions runners or local ARM machines

Docker automatically pulls the correct architecture for your platform.

## Projects Using This Image

- [binmgr/ffmpeg](https://github.com/binmgr/ffmpeg) - Static FFmpeg binaries

## Contributing

1. Fork the repository
2. Create your feature branch
3. Test the Docker image build
4. Submit a pull request

## License

MIT License - see LICENSE.md for details
