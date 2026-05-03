# Top-level driver. Per-tool builds live in Linux/<tool>/Makefile via
# Linux/Makefile; integration tests live under tests/ and use the
# locally built host tools, the vendored runtime, and the published
# RunCPM Docker image to verify the toolchain end-to-end.
#
#   make build              builds the 18 host tools (Linux/Install/)
#   make integration-test   builds + runs the integration tests
#   make clean              cleans both subtrees

.PHONY: all build integration-test clean

all: build

build:
	$(MAKE) -C Linux

integration-test: build
	$(MAKE) -C tests check

clean:
	$(MAKE) -C Linux distclean
	$(MAKE) -C tests clean
