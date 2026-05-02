# Todo — macOS port and toolchain validation

Working file per `AGENT.md` conventions. Mark `[x]` as items land. Add a brief
note next to each completed item describing how it was verified.

## In progress / pending

- [ ] **Investigate CI smoke-test failure.** GitHub Actions smoke step
      (`.github/workflows/build.yml` -> "End-to-end smoke test") is
      currently `continue-on-error: true`. On `ubuntu-latest` the chain
      trips a glibc stack canary somewhere between cgen and zas
      (`*** stack smashing detected ***: terminated`); on
      `macos-latest` (case-sensitive APFS) it fails earlier with
      `hello.obj: hello.obj: Can't open`. Same test passes locally on
      the maintainer's macOS Apple clang and via `Scripts/check.sh`. Both
      symptoms suggest a pre-existing latent bug in the host tools
      that's masked by case-insensitive APFS + Apple clang's defaults.
      Repro: install the workflow's exact toolchain locally
      (Ubuntu 22.04 gcc, GitHub macos-latest's APFS layout) or attach
      `keepi`/`keepp1`/`keepas` flags in the workflow to see which step
      crashes.

- [ ] **(Optional, upstream) Re-Huffman `LIBRARY.HUF` with fixes baked in.**
      Bugs documented in `cgen/nikitin/KNOWN_BUGS.md`. Re-Huffmanning would
      change a contributed binary archive — escalate to `markogden/hitech`
      rather than carrying the rewrite in this fork. Verify
      `cgen/native/unpack.pl` still reads a re-generated `LIBRARY.HUF`
      identically before any such change.

- [ ] **Track ogdenpm/hitech#5 review.** Three-commit PR
      (enhuff + cpp.c:1895 + KNOWN_BUGS.md) opened 2026-05-02 with
      explicit user authorisation. Watch for maintainer response;
      rebase / split / re-message as requested. If merged, drop this
      entry and close the loop in `tasks/upstream.md`. Other potential
      upstream items (`runtime/` vendoring, AGENTS.md/CLAUDE.md,
      re-Huffman'ing LIBRARY.HUF) were deliberately held back from
      PR #5 — discuss with the maintainer separately if interest is shown.

## Done — 2026-05-02

- [x] **Verified `enhuff` and `cpp.c:1895` fixes do not affect any
      CP/M cross-build path.** Inspection-based, no `zxcc` needed:

      1. Neither `enhuff/` nor `cpp/` has a `cpm/` or `native/`
         subdirectory — only `cgen`, `link`, `p1`, `libr4`, `zas` carry
         in-tree CP/M cross-build paths. So there is no cross-build of
         these specific tools' own source to break.
      2. For users' source code being *cross-compiled* via `zc`, the
         CPM target table (`zc/zc.c:78-87`) always sets `-DCPM` (and
         `-DCPMEX` on full-CPM targets). The original negative tests
         and the new positive tests both correctly identify CP/M:

         | Old test                                    | CPM (`-DCPM`) | macOS (Apple clang) | Linux (gcc) |
         | ------------------------------------------- | ------------- | ------------------- | ----------- |
         | `#if !defined(unix) && !defined(_WIN32)`    | true          | true (BUG)          | false       |
         | `#if defined(unix) \|\| defined(_WIN32)`    | false         | false (BUG)         | true        |
         | `#if CPM` / `#ifndef CPM` (after fix)       | true / false  | false / true        | false / true |

         The fixes are no-ops on CP/M and on Linux; they correct only
         the macOS column. So the CP/M cross-build path is unaffected
         in principle even if a `cpp/cpm/` or `enhuff/cpm/` Makefile
         were added later.

- [x] **Vendored the Z80 target runtime under `runtime/`.** 22
      standard headers (`runtime/include80/`), runtime libraries +
      startup objects (`runtime/lib80/`), the HI-TECH freeware license
      (`runtime/LICENSE.HITECH`), a sourceable env helper
      (`runtime/env.sh`) and a provenance/usage README
      (`runtime/README.md`). Files come from Tony Nicholson's
      `agn453/HI-TECH-Z80-C` `dist/` snapshot of 2026-05-02. End-to-end
      verified: `source runtime/env.sh && zc hi.c` produces a working
      `hi.com` that runs under RunCPM. CLAUDE.md and AGENTS.md updated
      to point at it.

- [x] **Verified `hello.com` runs under a CP/M emulator.** RunCPM v6.7
      (already built at `/Users/ravn/git/RunCPM/`, not in this repo)
      loads `HELLO.COM` from `RunCPM/RunCPM/A/0/`, executes the
      macOS-built 8460-byte binary, and prints `hello, z80!` followed by
      a clean return to the `A0>` prompt. End-to-end pipeline
      (cpp → p1 → cgen → optim → zas → link → objtohex on macOS,
      linked against `agn453/dist/LIBC.LIB`) confirmed working at
      runtime, not just by inspection.

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
