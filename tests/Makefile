# Integration tests for the HI-TECH C 3.09 host toolchain.
#
# Each runtime test is a small .c file that compiles to a CP/M .com,
# runs inside the published RunCPM Docker image, and diffs its captured
# output against a .expected file. One negative test verifies that
# malformed C is rejected at compile time.
#
# Run from repo root:  make integration-test
# Run standalone:      make -C tests check
#
# Requires:
#   - Linux/Install/ populated (the 18 host tools)
#   - runtime/ vendored
#   - docker available locally
#   - ghcr.io/ravn/hitech:runcpm-latest pullable (no auth needed; public)

ROOT       := $(realpath ..)
INSTALL    := $(ROOT)/Linux/Install
RUNTIME    := $(ROOT)/runtime
RUNCPM_IMG ?= ghcr.io/ravn/hitech:runcpm-latest
export RUNCPM_IMG

# How to invoke zc. Default uses the locally built host tool plus the
# vendored runtime tree. CI overrides with a docker-run pointing at the
# published hitech image so the test exercises the image, not the
# runner's gcc-built copy.
ZC ?= zc

export PATH      := $(INSTALL):$(PATH)
export INCDIR80  := $(RUNTIME)/include80
export LIBDIR80  := $(RUNTIME)/lib80

# Test names. Each is an 8.3-compatible basename so CP/M can load it.
RUNTIME_TESTS      := hello prfmt strops arith pair
COMPILE_FAIL_TESTS := badsyn
ALL_TESTS          := $(RUNTIME_TESTS) $(COMPILE_FAIL_TESTS)

.PHONY: check clean help $(ALL_TESTS:%=run-%)

help:
	@echo "Targets:"
	@echo "  check    compile + run + diff every test (default)"
	@echo "  clean    remove generated .com / .raw / .actual files"

check: $(ALL_TESTS:%=run-%)
	@printf '\n\033[32mall %d integration tests passed\033[0m\n' $(words $(ALL_TESTS))

clean:
	rm -f *.com *.raw *.actual

# --- compilation rules -----------------------------------------------------

# Single-file default.
%.com: %.c
	@$(ZC) $< > /dev/null 2>&1 || { echo "compile failed for $<"; $(ZC) $< ; false; }

# pair links two source files.
pair.com: pair.c pairlib.c
	@$(ZC) $^ -opair.com > /dev/null 2>&1 || { echo "compile failed for $^"; $(ZC) $^ -opair.com ; false; }

# --- per-test rules --------------------------------------------------------

define runtime_rule
run-$(1): $(1).com $(1).expected
	@./lib/run-test.sh $(1)
endef
$(foreach t,$(RUNTIME_TESTS),$(eval $(call runtime_rule,$(t))))

# Compile-failure test: zc must exit non-zero on this input.
run-badsyn: badsyn.c
	@if $(ZC) badsyn.c -obadsyn.com > /dev/null 2>&1; then \
	    printf '\033[31mFAIL\033[0m badsyn (compile unexpectedly succeeded)\n'; \
	    rm -f badsyn.com; exit 1; \
	else \
	    printf '\033[32mPASS\033[0m badsyn (compile failed as expected)\n'; \
	    rm -f badsyn.com; \
	fi
