ROOT_DIR := $(CURDIR)
UYA_BOOTSTRAP ?= ../uya/bin/uya
UYA_BUILD_FLAGS ?= --opt=2 --no-split-c
BOOTSTRAP_SRC := build/bootstrap/seed/main.uya
BIN_DIR := bin
BIN := $(BIN_DIR)/uyabuild

.PHONY: all bootstrap clean test test-unit test-golden benchmark-baseline

all: bootstrap

bootstrap: $(BIN)

$(BIN): $(BOOTSTRAP_SRC) | $(BIN_DIR)
	"$(UYA_BOOTSTRAP)" build "$(BOOTSTRAP_SRC)" -o "$@" $(UYA_BUILD_FLAGS)

$(BIN_DIR):
	mkdir -p $@

clean:
	rm -rf .uyacache "$(BIN)"

test: test-unit test-golden

test-unit: bootstrap
	./scripts/run-unit-tests.sh

test-golden: bootstrap
	./scripts/run-golden-tests.sh

benchmark-baseline: bootstrap
	./scripts/benchmark-baseline.sh
