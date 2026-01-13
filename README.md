# binmgr/toolchain

General-purpose Docker image for building truly static binaries across multiple platforms.

## Features

- **Alpine Linux base** with musl libc for truly portable static binaries
- **Zero dynamic dependencies** - binaries run anywhere
- **Multi-platform support**:
  - Linux AMD64 (native)
  - Linux ARM64 (cross-compile)
  - Windows AMD64 (cross-compile)
  - Windows ARM64 (cross-compile)

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
      - target: linux-amd64
        cc: gcc
        cxx: g++
      - target: linux-arm64
        cc: aarch64-linux-gcc
        cxx: aarch64-linux-g++
      - target: windows-amd64
        cc: x86_64-w64-mingw32-gcc
        cxx: x86_64-w64-mingw32-g++
      - target: windows-arm64
        cc: aarch64-w64-mingw32-gcc
        cxx: aarch64-w64-mingw32-g++

steps:
  - name: Build
    run: |
      export CC=${{ matrix.cc }}
      export CXX=${{ matrix.cxx }}
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
```

## Included Tools

- **Compilers**: GCC, Clang, MinGW
- **Build systems**: Make, CMake, Meson, Ninja
- **Assemblers**: NASM, YASM
- **Utilities**: Git, wget, curl, rsync
- **Static libraries**: zlib, OpenSSL, bzip2, xz, ncurses

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

## Projects Using This Image

- [binmgr/ffmpeg](https://github.com/binmgr/ffmpeg) - Static FFmpeg binaries

## Contributing

1. Fork the repository
2. Create your feature branch
3. Test the Docker image build
4. Submit a pull request

## License

MIT License - see LICENSE.md for details
