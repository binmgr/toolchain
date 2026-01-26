#!/bin/bash
# =============================================================================
# Cosmopolitan Universal Binary Template
# =============================================================================
# Usage: ./scripts/build-cosmo.sh [source-file] [output-name]
#
# Cosmopolitan creates truly universal binaries that run on:
# - Linux (x86_64, aarch64)
# - macOS (x86_64, aarch64)
# - Windows (x86_64)
# - FreeBSD, OpenBSD, NetBSD
#
# Example:
#   docker run --rm -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest \
#       ./scripts/build-cosmo.sh main.c myapp
# =============================================================================

set -e

SOURCE="${1:-main.c}"
OUTPUT="${2:-app}"

echo "Building universal binary with Cosmopolitan"
echo "Source: $SOURCE"
echo "Output: $OUTPUT.com"

# Verify cosmocc is available
if ! command -v cosmocc &>/dev/null; then
    echo "error: cosmocc not found. Make sure you're using the toolchain image."
    exit 1
fi

# Build with cosmocc
cosmocc \
    -O2 \
    -o "${OUTPUT}.com" \
    "$SOURCE"

echo ""
echo "Build complete!"
echo ""
echo "Binary: ${OUTPUT}.com"
echo "Size: $(ls -lh "${OUTPUT}.com" | awk '{print $5}')"
echo ""
echo "This binary runs on:"
echo "  - Linux (x86_64, aarch64)"
echo "  - macOS (x86_64, aarch64)"
echo "  - Windows (x86_64)"
echo "  - FreeBSD, OpenBSD, NetBSD (x86_64)"
echo ""
echo "Usage:"
echo "  Linux/macOS/BSD: ./${OUTPUT}.com"
echo "  Windows:         ${OUTPUT}.com.exe (rename or use as-is)"
