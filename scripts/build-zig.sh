#!/bin/bash
# =============================================================================
# Zig Cross-Compilation Template
# =============================================================================
# Usage: ./scripts/build-zig.sh [target] [source-file] [output-name]
#
# Zig can cross-compile to virtually any platform!
#
# Targets: linux-amd64, linux-arm64, linux-armv7, linux-riscv64,
#          windows-amd64, windows-arm64, macos-amd64, macos-arm64,
#          freebsd-amd64, wasm
#
# Example:
#   docker run --rm -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest \
#       ./scripts/build-zig.sh linux-arm64 src/main.zig myapp
# =============================================================================

set -e

TARGET="${1:-linux-amd64}"
SOURCE="${2:-main.zig}"
OUTPUT="${3:-app}"

# Map targets to Zig targets
declare -A ZIG_TARGETS=(
    ["linux-amd64"]="x86_64-linux-musl"
    ["linux-arm64"]="aarch64-linux-musl"
    ["linux-armv7"]="arm-linux-musleabihf"
    ["linux-riscv64"]="riscv64-linux-musl"
    ["windows-amd64"]="x86_64-windows-gnu"
    ["windows-arm64"]="aarch64-windows-gnu"
    ["macos-amd64"]="x86_64-macos"
    ["macos-arm64"]="aarch64-macos"
    ["freebsd-amd64"]="x86_64-freebsd"
    ["freebsd-arm64"]="aarch64-freebsd"
    ["wasm"]="wasm32-wasi"
)

ZIG_TARGET="${ZIG_TARGETS[$TARGET]}"

if [ -z "$ZIG_TARGET" ]; then
    echo "error: Unknown target: $TARGET"
    echo "Available targets: ${!ZIG_TARGETS[*]}"
    exit 1
fi

# Output file extension
EXT=""
case "$TARGET" in
    windows-*) EXT=".exe" ;;
    wasm) EXT=".wasm" ;;
esac

OUTPUT_FILE="${OUTPUT}-${TARGET}${EXT}"

echo "Building for $TARGET (Zig target: $ZIG_TARGET)"

# Build with Zig
zig build-exe \
    -target "$ZIG_TARGET" \
    -O ReleaseFast \
    --name "${OUTPUT}-${TARGET}" \
    "$SOURCE"

# Move to expected location
if [ -f "${OUTPUT}-${TARGET}" ]; then
    mv "${OUTPUT}-${TARGET}" "$OUTPUT_FILE"
fi

echo ""
echo "Build complete!"
echo "Binary: $OUTPUT_FILE"
echo "Size: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
