#!/bin/bash
# =============================================================================
# Rust Cross-Compilation Template
# =============================================================================
# Usage: ./scripts/build-rust.sh [target]
#
# Targets: linux-amd64, linux-arm64, linux-armv7, linux-riscv64,
#          windows-amd64, windows-arm64, darwin-amd64, darwin-arm64,
#          wasm32-unknown-unknown, wasm32-wasi
#
# Example:
#   docker run --rm -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest \
#       ./scripts/build-rust.sh linux-arm64
# =============================================================================

set -e

TARGET="${1:-linux-amd64}"

# Map our targets to Rust targets
declare -A RUST_TARGETS=(
    ["linux-amd64"]="x86_64-unknown-linux-musl"
    ["linux-arm64"]="aarch64-unknown-linux-musl"
    ["linux-armv7"]="armv7-unknown-linux-musleabihf"
    ["linux-riscv64"]="riscv64gc-unknown-linux-gnu"
    ["windows-amd64"]="x86_64-pc-windows-gnu"
    ["windows-arm64"]="aarch64-pc-windows-gnullvm"
    ["darwin-amd64"]="x86_64-apple-darwin"
    ["darwin-arm64"]="aarch64-apple-darwin"
    ["wasm32"]="wasm32-unknown-unknown"
    ["wasi"]="wasm32-wasi"
)

# Map targets to linkers
declare -A LINKERS=(
    ["linux-amd64"]="gcc"
    ["linux-arm64"]="aarch64-linux-gcc"
    ["linux-armv7"]="armv7-linux-gcc"
    ["linux-riscv64"]="riscv64-linux-gcc"
    ["windows-amd64"]="x86_64-w64-mingw32-gcc"
    ["windows-arm64"]="aarch64-w64-mingw32-clang"
    ["darwin-amd64"]="x86_64-apple-darwin23-clang"
    ["darwin-arm64"]="aarch64-apple-darwin23-clang"
)

RUST_TARGET="${RUST_TARGETS[$TARGET]}"

if [ -z "$RUST_TARGET" ]; then
    echo "error: Unknown target: $TARGET"
    echo "Available targets: ${!RUST_TARGETS[*]}"
    exit 1
fi

echo "Building for $TARGET (Rust target: $RUST_TARGET)"

# Install target if needed
rustup target add "$RUST_TARGET" 2>/dev/null || true

# Set linker for cross-compilation
LINKER="${LINKERS[$TARGET]}"
if [ -n "$LINKER" ]; then
    export CARGO_TARGET_$(echo "$RUST_TARGET" | tr '[:lower:]-' '[:upper:]_')_LINKER="$LINKER"
fi

# Build
RUSTFLAGS="-C target-feature=+crt-static" cargo build --release --target "$RUST_TARGET"

echo ""
echo "Build complete! Binary at: target/$RUST_TARGET/release/"
