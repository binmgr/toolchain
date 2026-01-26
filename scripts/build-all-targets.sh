#!/bin/bash
# =============================================================================
# Build for All Targets Template
# =============================================================================
# Usage: ./scripts/build-all-targets.sh [build-command]
#
# Builds for all major targets in sequence.
# The build command receives TARGET as an environment variable.
#
# Example:
#   docker run --rm -v $(pwd):/workspace ghcr.io/binmgr/toolchain:latest \
#       ./scripts/build-all-targets.sh "make clean all"
# =============================================================================

set -e

BUILD_CMD="${1:-make}"

# Core targets to build for
TARGETS=(
    "linux-amd64"
    "linux-arm64"
    "linux-armv7"
    "linux-riscv64"
    "windows-amd64"
    "windows-arm64"
    "darwin-amd64"
    "darwin-arm64"
    "freebsd-amd64"
)

echo "Building for ${#TARGETS[@]} targets"
echo "Build command: $BUILD_CMD"
echo ""

FAILED=()
SUCCEEDED=()

for target in "${TARGETS[@]}"; do
    echo "=============================================="
    echo "Building for: $target"
    echo "=============================================="

    # Setup target environment
    export TARGET="$target"

    # Source entrypoint to set up environment
    source /usr/local/bin/entrypoint.sh --setup "$target" 2>/dev/null || true

    # Run build
    if eval "$BUILD_CMD"; then
        echo ""
        echo "SUCCESS: $target"
        SUCCEEDED+=("$target")
    else
        echo ""
        echo "FAILED: $target"
        FAILED+=("$target")
    fi

    echo ""
done

# Summary
echo "=============================================="
echo "Build Summary"
echo "=============================================="
echo ""
echo "Succeeded (${#SUCCEEDED[@]}):"
for t in "${SUCCEEDED[@]}"; do
    echo "  - $t"
done
echo ""

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "Failed (${#FAILED[@]}):"
    for t in "${FAILED[@]}"; do
        echo "  - $t"
    done
    echo ""
    exit 1
fi

echo "All builds completed successfully!"
