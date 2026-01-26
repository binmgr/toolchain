#!/bin/bash
# =============================================================================
# Update SHA256 Checksums
# =============================================================================
# Downloads all toolchain artifacts and computes their SHA256 checksums.
# Updates versions.env with the computed values.
#
# Usage: ./scripts/update-checksums.sh
# =============================================================================

set -e

echo "Updating SHA256 checksums for toolchain downloads..."
echo ""

# Read current versions
source versions.env 2>/dev/null || true

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

compute_sha256() {
    local url="$1"
    local name="$2"

    echo "Downloading: $name"
    echo "  URL: $url"

    local file="$TEMP_DIR/$name"
    if wget -q "$url" -O "$file" 2>/dev/null; then
        local sha=$(sha256sum "$file" | cut -d' ' -f1)
        echo "  SHA256: $sha"
        rm -f "$file"
        echo "$sha"
    else
        echo "  FAILED to download"
        echo "SKIP"
    fi
}

echo "Computing checksums..."
echo ""

# Bootlin toolchains
echo "=== Bootlin Toolchains ==="
BOOTLIN_AARCH64_SHA256=$(compute_sha256 \
    "https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--musl--stable-${BOOTLIN_VERSION:-2024.02-1}.tar.bz2" \
    "bootlin-aarch64.tar.bz2")

BOOTLIN_ARMV7_SHA256=$(compute_sha256 \
    "https://toolchains.bootlin.com/downloads/releases/toolchains/armv7-eabihf/tarballs/armv7-eabihf--musl--stable-${BOOTLIN_VERSION:-2024.02-1}.tar.bz2" \
    "bootlin-armv7.tar.bz2")

BOOTLIN_RISCV64_SHA256=$(compute_sha256 \
    "https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-lp64d/tarballs/riscv64-lp64d--musl--stable-${BOOTLIN_VERSION:-2024.02-1}.tar.bz2" \
    "bootlin-riscv64.tar.bz2")

echo ""
echo "=== LLVM MinGW ==="
LLVM_MINGW_SHA256=$(compute_sha256 \
    "https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION:-20241217}/llvm-mingw-${LLVM_MINGW_VERSION:-20241217}-ucrt-ubuntu-20.04-x86_64.tar.xz" \
    "llvm-mingw.tar.xz")

echo ""
echo "=== Zig ==="
ZIG_AMD64_SHA256=$(compute_sha256 \
    "https://ziglang.org/download/${ZIG_VERSION:-0.13.0}/zig-linux-x86_64-${ZIG_VERSION:-0.13.0}.tar.xz" \
    "zig-amd64.tar.xz")

ZIG_ARM64_SHA256=$(compute_sha256 \
    "https://ziglang.org/download/${ZIG_VERSION:-0.13.0}/zig-linux-aarch64-${ZIG_VERSION:-0.13.0}.tar.xz" \
    "zig-arm64.tar.xz")

echo ""
echo "=== Summary ==="
echo "BOOTLIN_AARCH64_SHA256=$BOOTLIN_AARCH64_SHA256"
echo "BOOTLIN_ARMV7_SHA256=$BOOTLIN_ARMV7_SHA256"
echo "BOOTLIN_RISCV64_SHA256=$BOOTLIN_RISCV64_SHA256"
echo "LLVM_MINGW_SHA256=$LLVM_MINGW_SHA256"
echo "ZIG_AMD64_SHA256=$ZIG_AMD64_SHA256"
echo "ZIG_ARM64_SHA256=$ZIG_ARM64_SHA256"
echo ""
echo "Update versions.env with these values manually."
