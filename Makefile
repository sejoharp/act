.DEFAULT_GOAL:= help
ACT_RELEASE_VERSION := $(shell git rev-list --count HEAD).0.0
.PHONY:dependencies 
dependencies: ## downloads and installs dependencies
	cargo update

.PHONY:test 
test: ## executes tests
	cargo test

.PHONY:build
build: ## builds binary with debug infos
	cargo build

.PHONY:new_version
new_version: ## builds binary with debug infos
	@echo "$(ACT_RELEASE_VERSION)"

.PHONY:version_update
version_update: ## updates version in Cargo.toml
	sed -i.bak "s/^version = \".*\"/version = \"$(ACT_RELEASE_VERSION)\"/" Cargo.toml 2>/dev/null

.PHONY:release
release: version_update ## builds release binary
	cargo build --release

.PHONY: install
install: release ## builds and installs `act` binary into ~/bin directory
	cp target/release/act ~/bin/act

.PHONY: help	
help: ## shows help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)