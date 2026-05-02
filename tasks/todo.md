# Todo — macOS port and toolchain validation

Working file per `AGENT.md` conventions. Mark `[x]` as items land. Add a brief
note next to each completed item describing how it was verified.

## In progress / pending

- [ ] **Verify `cpp.c` `#ifndef CPM` change preserves CP/M cross-build.**
      Companion to task #5 (enhuff). The line-1895 fix is functionally
      identical to the original on Linux + Windows (where `unix` /
      `_WIN32` was defined), and now also runs on macOS. CP/M cross-build
      path (which sets `-DCPM`) needs explicit verification — same
      caveat as enhuff: `cpp/cpm/` Makefile not present in repo.

- [ ] **Add reproducible runtime tree.** Turn the throwaway
      `/tmp/hitech-test/` setup into a permanent `Linux/runtime/` (or
      top-level `dist/`) Makefile target. Vendor or fetch the
      `agn453/HI-TECH-Z80-C` `dist/` files (headers + LIBC.LIB + LIBF.LIB +
      crt obj variants) into a known location alongside `Linux/Install/`,
      with attribution and licence note. Decide vendoring vs. fetch-at-build.
      Result: fresh clone → `make && make runtime` → working `zc hello.c`.

- [ ] **Verify `hello.com` actually executes under a CP/M emulator.**
      Currently the toolchain's correctness is verified by binary inspection
      only. Install one of `zxcc` / `tnylpo` / `runcpm` (not in Homebrew —
      build from source) and confirm a built `.com` actually runs and
      prints. Document the chosen emulator in `AGENTS.md`.

- [ ] **(Optional, upstream) Re-Huffman `LIBRARY.HUF` with fixes baked in.**
      Bugs documented in `cgen/nikitin/KNOWN_BUGS.md`. Re-Huffmanning would
      change a contributed binary archive — escalate to `markogden/hitech`
      rather than carrying the rewrite in this fork. Verify
      `cgen/native/unpack.pl` still reads a re-generated `LIBRARY.HUF`
      identically before any such change.

- [ ] **Verify the `enhuff` `#ifdef CPM` change preserves CP/M cross-build.**
      The fix is functionally equivalent on the modern host (neither side
      executes), but the CP/M cross-build path (zxcc-based) needs
      verification. The new test must be true on CP/M; `zc.c`'s targets
      table sets `-DCPM`, suggesting the macro is defined during
      cross-builds, but no `enhuff/cpm/` Makefile exists to confirm.
      Either inspect the cross-build flag set, or add an `enhuff/cpm/`
      Makefile and run under `zxcc`.

- [ ] **Decide upstream contribution path.** Remote is
      `git@github.com:ravn/hitech.git` (personal fork). The `enhuff` fix
      and the `AGENTS.md` / `CLAUDE.md` improvements are upstream-quality
      for `markogden/hitech` (or wherever the canonical fork lives). Confirm
      upstream URL, decide whether to open a PR, split into commits the
      maintainer will accept (likely separate the C fix from the docs
      rewrite). Note: original `AGENTS.md` was copied from a different
      project — upstream may not want that file at all.

## Done — 2026-05-02

- [x] **Documented `LIBRARY.HUF` transcription bugs in
      `cgen/nikitin/KNOWN_BUGS.md`.** `sprintf.asm:21`
      (`ld (_spf+2),h` → `ld (_spf+2),hl`) and `pnum.asm:56`
      (`call __pnum` → `call _pnum`). Both confirmed by reading the
      extracted files; right-column comments preserve the original
      correct mnemonics. Archive itself left untouched as a verbatim
      record of Nikitin's contribution.

- [x] **`cpp/cpp.c:1895` macOS portability fix.** Replaced
      `#if defined(unix) || defined(_WIN32)` with `#ifndef CPM`. Full
      `Linux/` build clean after change.
      **Surprise finding:** the bug is *latent*, not observable. Initial
      analysis assumed the missing `dirs[0] = dirnams[0] = "."` init
      would break `#include` resolution. In practice it does not, because
      line 1985 (`dirs[0] = dirnams[ifno] = trmdir(argv[i])`) overwrites
      `dirs[0]` whenever a source filename is provided (including the
      synthetic argv produced by `_getargs` at line 1856 when `argc==1`).
      The original reproducer (`cpp < driver.c` containing
      `#include "local.h"`) failed for an unrelated reason: `_getargs`
      tokenises stdin into argv on the no-args path, treating `#include`
      and `"local.h"` as flags. Apple-clang skipping line 1895 has no
      observable effect on any code path I can construct. The fix is
      still correct as code hygiene — matches the project's positive
      `CPM` convention and removes the surprising negative test that
      Apple clang silently mishandles. Documented latency in the commit
      message.

- [x] **`enhuff/enhuff.c` macOS portability fix.** Replaced
      `#if !defined(unix) && !defined(_WIN32)` with `#if CPM`. Verified by
      rebuilding `enhuff` from clean (`make -C Linux/enhuff rebuild`) and
      confirming the full `make` in `Linux/` now succeeds end-to-end past
      enhuff. Pattern matches `dehuff/dehuff.c:29`.

- [x] **All 18 tools build cleanly on macOS.** Apple clang 21.0.0 /
      `arm64-apple-darwin25.4.0` (`/usr/bin/cc` and `/usr/bin/gcc` both
      resolve to clang on this Mac with Xcode CLT). `Linux/Install/`
      contains all 18 binaries. Smoke-tested `-V` flag on `cgen`, `zas`,
      `p1` — all report version, build date, contributors as expected.

- [x] **End-to-end pipeline reaches CP/M `.com`.** `int main() { return
      42; }` round-trips through `cpp → p1 → cgen → zas → link →
      objtohex` to a 224-byte CP/M COM file. Verified by hex inspection:
      startup sequence matches `crtcpm.obj`'s text section exactly,
      `LD HL,42` for `return 42;` visible at offset `0x44`. Not yet
      executed under a CP/M emulator (see open task).

- [x] **End-to-end pipeline with stdio works.** `printf("hello, z80!\n")`
      compiled against the full `agn453/dist/LIBC.LIB` (85 KB) plus
      `STDIO.H` produces an 8460-byte `.com` containing the literal
      `hello, z80!` string and the `Compiled with Hi-Tech C` signature.

- [x] **`CLAUDE.md` and `AGENTS.md` written for this repo.** `AGENTS.md`
      had been mistakenly copied from an unrelated Z80/LLVM project at some
      earlier point; rewritten as a project-specific AI-agent guide with
      the dual-target portability constraint, build workflows,
      decompilation conventions, and known macOS gaps. `CLAUDE.md` added as
      orientation for future Claude Code sessions.

- [x] **Identified `cgen/nikitin/LIBRARY.HUF` as bundled library source.**
      Contains `csv.asm` defining the runtime helpers `csv` / `cret` /
      `indir` / `ncsv` that were missing from `mkpat/test/libc80.lib`.
      Built a working `libcrt.lib` from 43 of 45 extracted `.asm` files
      (the 2 failures tracked above as a separate decompilation-bug task).

- [x] **Identified bundled `STDIO.H` inside `cgen/nikitin/CGEN.HUF`.**
      A real Z80-target stdio.h with proper `_iob`/`FILE`/`EOF`/`BUFSIZ`
      and prototypes lining up with the `LIBC.LIB` symbols. The other 22
      standard headers are not in this repo; they were sourced from
      `agn453/HI-TECH-Z80-C/dist/`.
