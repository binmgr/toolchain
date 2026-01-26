#!/bin/bash
# =============================================================================
# Go Cross-Compilation Template
# =============================================================================
# Usage: ./scripts/build-go.sh [target] [output-name]
#
# Targets: linux-amd64, linux-arm64, linux-armv7, linux-riscv64,
#          windows-amd64, windows-arm64, darwin-amd64, darwin-arm64,
#          freebsd-amd64, freebsd-arm64, openbsd-amd64, netbsd-amd64,
#          wasm
#
# Example:
#   docker run --rm -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest \
#       ./scripts/build-go.sh linux-arm64 myapp
# =============================================================================

set -e

TARGET="${1:-linux-amd64}"
OUTPUT="${2:-app}"

# Map targets to GOOS/GOARCH
declare -A GO_OS=(
    ["linux-amd64"]="linux"
    ["linux-arm64"]="linux"
    ["linux-armv7"]="linux"
    ["linux-riscv64"]="linux"
    ["windows-amd64"]="windows"
    ["windows-arm64"]="windows"
    ["darwin-amd64"]="darwin"
    ["darwin-arm64"]="darwin"
    ["freebsd-amd64"]="freebsd"
    ["freebsd-arm64"]="freebsd"
    ["openbsd-amd64"]="openbsd"
    ["openbsd-arm64"]="openbsd"
    ["netbsd-amd64"]="netbsd"
    ["netbsd-arm64"]="netbsd"
    ["illumos-amd64"]="illumos"
    ["wasm"]="js"
)

declare -A GO_ARCH=(
    ["linux-amd64"]="amd64"
    ["linux-arm64"]="arm64"
    ["linux-armv7"]="arm"
    ["linux-riscv64"]="riscv64"
    ["windows-amd64"]="amd64"
    ["windows-arm64"]="arm64"
    ["darwin-amd64"]="amd64"
    ["darwin-arm64"]="arm64"
    ["freebsd-amd64"]="amd64"
    ["freebsd-arm64"]="arm64"
    ["openbsd-amd64"]="amd64"
    ["openbsd-arm64"]="arm64"
    ["netbsd-amd64"]="amd64"
    ["netbsd-arm64"]="arm64"
    ["illumos-amd64"]="amd64"
    ["wasm"]="wasm"
)

GOOS="${GO_OS[$TARGET]}"
GOARCH="${GO_ARCH[$TARGET]}"

if [ -z "$GOOS" ]; then
    echo "error: Unknown target: $TARGET"
    echo "Available targets: ${!GO_OS[*]}"
    exit 1
fi

# Output file extension
EXT=""
case "$GOOS" in
    windows) EXT=".exe" ;;
    js) EXT=".wasm" ;;
esac

OUTPUT_FILE="${OUTPUT}-${TARGET}${EXT}"

echo "Building for $TARGET (GOOS=$GOOS GOARCH=$GOARCH)"

# Set environment
export GOOS GOARCH
export CGO_ENABLED=0

# Build flags for static binary
LDFLAGS="-s -w -extldflags '-static'"

# Build
go build -ldflags="$LDFLAGS" -o "$OUTPUT_FILE" .

echo ""
echo "Build complete!"
echo "Binary: $OUTPUT_FILE"
echo "Size: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
