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
# Each runtime source runs twice: once with default codegen, once with
# `zc -O` (the optim peephole pass) to guard against optim regressions
# like issue #1 silently slipping past CI. Output filename for -O cells
# has an 'O' suffix (e.g. helloO.com) to stay 8.3-safe in CP/M; that
# matches the `A0>HELLOO` CCP echo that extract-output.sh keys off.
RUNTIME_TESTS_BASE := hello prfmt strops arith pair
RUNTIME_TESTS_O    := $(RUNTIME_TESTS_BASE:%=%O)
RUNTIME_TESTS      := $(RUNTIME_TESTS_BASE) $(RUNTIME_TESTS_O)
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
	rm -f *.com *.raw *.actual $(RUNTIME_TESTS_O:%=%.expected)

# --- compilation rules -----------------------------------------------------

# Single-file default.
%.com: %.c
	@$(ZC) $< > /dev/null 2>&1 || { echo "compile failed for $<"; $(ZC) $< ; false; }

# pair links two source files.
pair.com: pair.c pairlib.c
	@$(ZC) $^ -opair.com > /dev/null 2>&1 || { echo "compile failed for $^"; $(ZC) $^ -opair.com ; false; }

# -O variants: invoke optim peephole pass. Same source(s) as the base
# cell, output goes to BASENAMEO.com (no separator, 8.3-safe).
helloO.com: hello.c
	@$(ZC) -O $< -OhelloO.com > /dev/null 2>&1 || { echo "compile failed for $< (-O)"; $(ZC) -O $< -OhelloO.com ; false; }
prfmtO.com: prfmt.c
	@$(ZC) -O $< -OprfmtO.com > /dev/null 2>&1 || { echo "compile failed for $< (-O)"; $(ZC) -O $< -OprfmtO.com ; false; }
stropsO.com: strops.c
	@$(ZC) -O $< -OstropsO.com > /dev/null 2>&1 || { echo "compile failed for $< (-O)"; $(ZC) -O $< -OstropsO.com ; false; }
arithO.com: arith.c
	@$(ZC) -O $< -OarithO.com > /dev/null 2>&1 || { echo "compile failed for $< (-O)"; $(ZC) -O $< -OarithO.com ; false; }
pairO.com: pair.c pairlib.c
	@$(ZC) -O $^ -OpairO.com > /dev/null 2>&1 || { echo "compile failed for pair (-O)"; $(ZC) -O $^ -OpairO.com ; false; }

# -O cells reuse the base .expected (optim must not change observable output).
$(RUNTIME_TESTS_O:%=%.expected): %O.expected: %.expected
	@cp -f $< $@

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
