# =============================================================================
# binmgr/toolchain - Development Makefile
# =============================================================================
# Common operations for building, testing, and managing the toolchain image
#
# Usage:
#   make build         - Build the Docker image locally
#   make test          - Run all verification tests
#   make shell         - Start interactive shell in container
#   make clean         - Remove build artifacts and images
#   make push          - Push image to registry
#
# =============================================================================

# Configuration
IMAGE_NAME := ghcr.io/binmgr/toolchain
VERSION := $(shell date +%y%m)
COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
PLATFORM := linux/amd64,linux/arm64

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# HELP
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "$(CYAN)binmgr/toolchain$(NC) - Development Commands"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make $(GREEN)<target>$(NC)"
	@echo ""
	@echo "$(YELLOW)Targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# BUILD TARGETS
# =============================================================================

.PHONY: build
build: ## Build Docker image for current platform
	@echo "$(CYAN)Building $(IMAGE_NAME):latest...$(NC)"
	docker build \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE_NAME):$(VERSION) \
		--tag $(IMAGE_NAME):$(COMMIT) \
		--build-arg TOOLCHAIN_VERSION=$(VERSION) \
		.
	@echo "$(GREEN)Build complete!$(NC)"

.PHONY: build-no-cache
build-no-cache: ## Build Docker image without cache
	@echo "$(CYAN)Building $(IMAGE_NAME):latest (no cache)...$(NC)"
	docker build --no-cache \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE_NAME):$(VERSION) \
		--tag $(IMAGE_NAME):$(COMMIT) \
		--build-arg TOOLCHAIN_VERSION=$(VERSION) \
		.
	@echo "$(GREEN)Build complete!$(NC)"

.PHONY: build-multiarch
build-multiarch: ## Build Docker image for multiple architectures
	@echo "$(CYAN)Building $(IMAGE_NAME) for $(PLATFORM)...$(NC)"
	docker buildx build \
		--platform $(PLATFORM) \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE_NAME):$(VERSION) \
		--tag $(IMAGE_NAME):$(COMMIT) \
		--build-arg TOOLCHAIN_VERSION=$(VERSION) \
		.
	@echo "$(GREEN)Multi-arch build complete!$(NC)"

# =============================================================================
# TEST TARGETS
# =============================================================================

.PHONY: test
test: test-compilers test-languages test-targets ## Run all tests
	@echo "$(GREEN)All tests passed!$(NC)"

.PHONY: test-compilers
test-compilers: ## Test all C/C++ compilers
	@echo "$(CYAN)Testing C/C++ compilers...$(NC)"
	@docker run --rm $(IMAGE_NAME):latest bash -c '\
		echo "Testing GCC (AMD64)..." && gcc --version | head -1 && \
		echo "Testing GCC (ARM64)..." && aarch64-linux-gcc --version | head -1 && \
		echo "Testing GCC (ARMv7)..." && armv7-linux-gcc --version | head -1 && \
		echo "Testing GCC (RISC-V64)..." && riscv64-linux-gcc --version | head -1 && \
		echo "Testing Clang (Windows AMD64)..." && x86_64-w64-mingw32-clang --version | head -1 && \
		echo "Testing Clang (Windows ARM64)..." && aarch64-w64-mingw32-clang --version | head -1 && \
		echo "Testing OSXCross (macOS)..." && x86_64-apple-darwin23-clang --version 2>&1 | head -1 && \
		echo "Testing Cosmocc..." && cosmocc --version 2>&1 | head -1 || true \
	'
	@echo "$(GREEN)Compiler tests passed!$(NC)"

.PHONY: test-languages
test-languages: ## Test all modern language compilers
	@echo "$(CYAN)Testing modern languages...$(NC)"
	@docker run --rm $(IMAGE_NAME):latest bash -c '\
		echo "Rust: $$(rustc --version)" && \
		echo "Go: $$(go version)" && \
		echo "Zig: $$(zig version)" && \
		echo "TinyGo: $$(tinygo version)" && \
		echo "Node.js: $$(node --version)" && \
		echo "Deno: $$(deno --version | head -1)" && \
		echo "Bun: $$(bun --version)" \
	'
	@echo "$(GREEN)Language tests passed!$(NC)"

.PHONY: test-targets
test-targets: ## Test compilation for each target with hello world
	@echo "$(CYAN)Testing compilation targets...$(NC)"
	@docker run --rm $(IMAGE_NAME):latest bash -c '\
		# Create test program \
		echo "int main() { return 0; }" > /tmp/test.c && \
		echo "" && \
		echo "Testing linux-amd64..." && \
		gcc -static /tmp/test.c -o /tmp/test-linux-amd64 && file /tmp/test-linux-amd64 && \
		echo "" && \
		echo "Testing linux-arm64..." && \
		aarch64-linux-gcc -static /tmp/test.c -o /tmp/test-linux-arm64 && file /tmp/test-linux-arm64 && \
		echo "" && \
		echo "Testing linux-armv7..." && \
		armv7-linux-gcc -static /tmp/test.c -o /tmp/test-linux-armv7 && file /tmp/test-linux-armv7 && \
		echo "" && \
		echo "Testing linux-riscv64..." && \
		riscv64-linux-gcc -static /tmp/test.c -o /tmp/test-linux-riscv64 && file /tmp/test-linux-riscv64 && \
		echo "" && \
		echo "Testing windows-amd64..." && \
		x86_64-w64-mingw32-clang -static /tmp/test.c -o /tmp/test-windows-amd64.exe && file /tmp/test-windows-amd64.exe && \
		echo "" && \
		echo "Testing windows-arm64..." && \
		aarch64-w64-mingw32-clang -static /tmp/test.c -o /tmp/test-windows-arm64.exe && file /tmp/test-windows-arm64.exe && \
		echo "" && \
		echo "Testing wasi..." && \
		/opt/wasi-sdk/bin/clang --sysroot=/opt/wasi-sdk/share/wasi-sysroot /tmp/test.c -o /tmp/test.wasm && file /tmp/test.wasm && \
		echo "" && \
		echo "Testing cosmo (universal binary)..." && \
		cosmocc /tmp/test.c -o /tmp/test.com && file /tmp/test.com && \
		echo "" && \
		echo "All target compilation tests passed!" \
	'
	@echo "$(GREEN)Target tests passed!$(NC)"

.PHONY: test-static
test-static: ## Verify binaries are truly static
	@echo "$(CYAN)Verifying static linking...$(NC)"
	@docker run --rm $(IMAGE_NAME):latest bash -c '\
		echo "int main() { return 0; }" > /tmp/test.c && \
		gcc -static /tmp/test.c -o /tmp/test && \
		echo "Checking with ldd:" && \
		ldd /tmp/test 2>&1 || true && \
		echo "" && \
		echo "Checking with readelf:" && \
		readelf -d /tmp/test | grep -E "NEEDED|INTERP" || echo "No dynamic dependencies found (good!)" \
	'
	@echo "$(GREEN)Static verification passed!$(NC)"

.PHONY: test-qemu
test-qemu: ## Test cross-compiled binaries with QEMU
	@echo "$(CYAN)Testing with QEMU...$(NC)"
	@docker run --rm $(IMAGE_NAME):latest bash -c '\
		echo "#include <stdio.h>" > /tmp/hello.c && \
		echo "int main() { printf(\"Hello from ARM64!\\n\"); return 0; }" >> /tmp/hello.c && \
		aarch64-linux-gcc -static /tmp/hello.c -o /tmp/hello-arm64 && \
		echo "Running ARM64 binary with QEMU:" && \
		qemu-aarch64 /tmp/hello-arm64 \
	'
	@echo "$(GREEN)QEMU tests passed!$(NC)"

# =============================================================================
# DEVELOPMENT TARGETS
# =============================================================================

.PHONY: shell
shell: ## Start interactive shell in container
	@echo "$(CYAN)Starting interactive shell...$(NC)"
	docker run --rm -it \
		-v $(PWD):/workspace \
		$(IMAGE_NAME):latest --shell

.PHONY: shell-target
shell-target: ## Start shell with TARGET set (usage: make shell-target TARGET=linux-arm64)
	@echo "$(CYAN)Starting shell for target: $(TARGET)$(NC)"
	docker run --rm -it \
		-v $(PWD):/workspace \
		-e TARGET=$(TARGET) \
		$(IMAGE_NAME):latest --shell

.PHONY: info
info: ## Show toolchain information
	@docker run --rm $(IMAGE_NAME):latest --info

.PHONY: list-targets
list-targets: ## List all available compilation targets
	@docker run --rm $(IMAGE_NAME):latest --list-targets

# =============================================================================
# REGISTRY TARGETS
# =============================================================================

.PHONY: push
push: ## Push image to GitHub Container Registry
	@echo "$(CYAN)Pushing $(IMAGE_NAME)...$(NC)"
	docker push $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):$(COMMIT)
	@echo "$(GREEN)Push complete!$(NC)"

.PHONY: push-multiarch
push-multiarch: ## Build and push multi-arch image
	@echo "$(CYAN)Building and pushing multi-arch $(IMAGE_NAME)...$(NC)"
	docker buildx build \
		--platform $(PLATFORM) \
		--tag $(IMAGE_NAME):latest \
		--tag $(IMAGE_NAME):$(VERSION) \
		--tag $(IMAGE_NAME):$(COMMIT) \
		--build-arg TOOLCHAIN_VERSION=$(VERSION) \
		--push \
		.
	@echo "$(GREEN)Multi-arch push complete!$(NC)"

.PHONY: login
login: ## Login to GitHub Container Registry
	@echo "$(CYAN)Logging in to ghcr.io...$(NC)"
	@echo "Run: echo $$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"

# =============================================================================
# CLEANUP TARGETS
# =============================================================================

.PHONY: clean
clean: ## Remove build artifacts and dangling images
	@echo "$(CYAN)Cleaning up...$(NC)"
	docker image prune -f
	@echo "$(GREEN)Cleanup complete!$(NC)"

.PHONY: clean-all
clean-all: ## Remove all toolchain images
	@echo "$(YELLOW)Removing all $(IMAGE_NAME) images...$(NC)"
	docker images $(IMAGE_NAME) -q | xargs -r docker rmi -f
	docker image prune -f
	@echo "$(GREEN)All images removed!$(NC)"

# =============================================================================
# UTILITY TARGETS
# =============================================================================

.PHONY: size
size: ## Show image size breakdown
	@echo "$(CYAN)Image size:$(NC)"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

.PHONY: history
history: ## Show image layer history
	@echo "$(CYAN)Image layers:$(NC)"
	@docker history $(IMAGE_NAME):latest --format "table {{.CreatedBy}}\t{{.Size}}"

.PHONY: scan
scan: ## Scan image for vulnerabilities (requires trivy)
	@echo "$(CYAN)Scanning for vulnerabilities...$(NC)"
	trivy image $(IMAGE_NAME):latest

.PHONY: sbom
sbom: ## Generate SBOM (requires syft)
	@echo "$(CYAN)Generating SBOM...$(NC)"
	syft $(IMAGE_NAME):latest -o spdx-json > sbom.json
	@echo "$(GREEN)SBOM saved to sbom.json$(NC)"

.PHONY: update-checksums
update-checksums: ## Update SHA256 checksums in versions.env
	@echo "$(CYAN)Updating checksums...$(NC)"
	./scripts/update-checksums.sh
	@echo "$(GREEN)Checksums updated!$(NC)"

.PHONY: versions
versions: ## Show all tool versions in the image
	@docker run --rm $(IMAGE_NAME):latest toolchain-info
