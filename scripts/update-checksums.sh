#!/bin/bash
# =============================================================================
# Compute SHA256 Checksums (Reference Tool)
# =============================================================================
# Downloads toolchain artifacts and computes SHA256 checksums.
# This is an optional reference tool - checksums are not required for builds.
#
# Usage: ./scripts/update-checksums.sh
# =============================================================================

set -e

source versions.env 2>/dev/null || true

echo "Computing SHA256 checksums for toolchain downloads..."
echo "This is for reference only - checksums are optional."
echo ""

compute() {
    local url="$1"
    local name="$2"
    echo -n "  $name: "
    local file=$(mktemp)
    if wget -q --timeout=60 "$url" -O "$file" 2>/dev/null; then
        sha256sum "$file" | cut -d' ' -f1
        rm -f "$file"
    else
        echo "FAILED"
    fi
}

echo "=== Bootlin Toolchains ==="
compute "https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--musl--stable-${BOOTLIN_VERSION:-2024.02-1}.tar.bz2" "aarch64"
compute "https://toolchains.bootlin.com/downloads/releases/toolchains/armv7-eabihf/tarballs/armv7-eabihf--musl--stable-${BOOTLIN_VERSION:-2024.02-1}.tar.bz2" "armv7"
compute "https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-lp64d/tarballs/riscv64-lp64d--musl--stable-${BOOTLIN_VERSION:-2024.02-1}.tar.bz2" "riscv64"

echo ""
echo "=== Other Toolchains ==="
compute "https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION:-20241217}/llvm-mingw-${LLVM_MINGW_VERSION:-20241217}-ucrt-ubuntu-20.04-x86_64.tar.xz" "llvm-mingw"
compute "https://ziglang.org/download/${ZIG_VERSION:-0.13.0}/zig-linux-x86_64-${ZIG_VERSION:-0.13.0}.tar.xz" "zig-amd64"
compute "https://download.freebsd.org/releases/amd64/${FREEBSD_VERSION:-14.3}-RELEASE/base.txz" "freebsd-base"

echo ""
echo "Done. These checksums are for reference only."
