# Todo — macOS port and toolchain validation

Working file per `AGENT.md` conventions. Mark `[x]` as items land. Add a brief
note next to each completed item describing how it was verified.

## In progress / pending

- [ ] **Pin the RunCPM upstream commit in `runcpm/Dockerfile`.** Right
      now the Dockerfile clones `MockbaTheBorg/RunCPM` at `--depth=1`
      from the moving `main` branch and extracts upstream's `A0.ZIP`
      master disk. If upstream renames `A0.ZIP`, changes the layout,
      or breaks API compatibility with the python wrapper's stdout
      heuristics, the next image rebuild will fail (or — worse —
      pass and produce subtly wrong behaviour). Replace the clone
      with a checkout of a specific tag or commit SHA, and bump
      deliberately. Low priority; the upstream is fairly stable.

- [ ] **(Optional, upstream) Re-Huffman `LIBRARY.HUF` with fixes baked in.**
      Bugs documented in `cgen/nikitin/KNOWN_BUGS.md`. Re-Huffmanning would
      change a contributed binary archive — escalate to `markogden/hitech`
      rather than carrying the rewrite in this fork. Verify
      `cgen/native/unpack.pl` still reads a re-generated `LIBRARY.HUF`
      identically before any such change.

- [ ] **CHECK ogdenpm/hitech#6 ON OR AFTER 2026-05-10.**
      Single-commit PR for the `cgen` `int cmp` unsigned-char fix,
      opened 2026-05-03. User-introduced; AI authorship clearly
      stated in the body. **Reviewing AI: when you read this on or
      after 2026-05-10, run `gh pr view 6 --repo ogdenpm/hitech --json
      state,reviewDecision,comments` and report state to the user.
      If still untouched (CLOSED/OPEN with zero comments and no
      review), suggest closing as we did with PR #5 — but ask first.**
      <https://github.com/ogdenpm/hitech/pull/6>

- [ ] **(Dormant) Re-engage upstream further when there's a signal Mark is active.**
      Other accumulated host-tool fixes (showVersion case, zc nerrs,
      runtime rename, plus the older PR-#5 contents) catalogued in
      `tasks/upstream.md`. Rather than another cold-open PR, watch
      <https://github.com/ogdenpm/hitech/commits/main> for new activity
      (last commit before our PRs was June 2025).

## Done — 2026-05-03

- [x] **CI test job runs the full integration suite via published images.**
      `.github/workflows/container.yml` `test` job no longer hand-rolls
      a single hello-world; it checks out the repo, pulls the
      just-published `:sha-<short>` hitech image and `:runcpm-latest`,
      and shells out to `make -C tests check` with `ZC=` and
      `RUNCPM_IMG=` overrides pointing at the docker images.
      `tests/Makefile` gained a `ZC ?= zc` parameter so the same
      Makefile serves both local development (native `zc`) and CI
      (docker-wrapped `zc` in the published image). Six tests run in
      ~4s on `ubuntu-24.04-arm`.

- [x] **RunCPM exits cleanly via `EXIT.COM` instead of SIGALRM.**
      `runcpm/Dockerfile` now extracts upstream's `A0.ZIP` master disk
      so `EXIT.COM` is on drive A:. `runcpm/runcpm-run` rewritten in
      Python: spawns RunCPM, watches stdout, counts `RunCPM Version`
      banners (the line-terminated marker for each CCP iteration),
      and sends `EXIT` after the second one — i.e. as soon as the
      user's program returns to the CCP. RunCPM halts cleanly,
      wrapper exits 0. A 30s `threading.Timer` watchdog catches
      runaway programs but never fires in normal operation.
      Integration suite: ~60s → ~1.7s. Single `docker run … hello.com`:
      ~10s → ~0.2s. Why `RunCPM Version` and not the `A0>` prompt:
      RunCPM emits the prompt without a trailing newline, so
      line-oriented scanners never see it.

- [x] **Integration test suite under `tests/`.** Six small `.c` programs
      compiled by the local `zc` and executed inside the runcpm image,
      each diffed against a committed `.expected` file:
      `hello`, `prfmt` (printf format specifiers — caught HI-TECH's
      uppercase `%x`), `strops` (`string.h`), `arith` (int arithmetic /
      cgen / optim), `pair` (multi-source linking), `badsyn` (negative
      compile-failure test). Top-level `Makefile` exposes
      `make integration-test`; `tests/lib/run-test.sh` is the
      per-test runner; `tests/lib/extract-output.sh` strips the
      RunCPM banner / prompt noise. `tests/.gitignore` keeps generated
      `.com / .raw / .actual / .obj` out of the index.

- [x] **PR #6 opened against `ogdenpm/hitech` for the cgen fix.** Single
      one-line commit (`char cmp` → `int cmp` in `sub_1B2`) on a
      cherry-pick branch from `upstream/main`. User-introduced;
      authorship clearly attributed to Claude in the body.
      <https://github.com/ogdenpm/hitech/pull/6>. Follow-up reminder
      dated 2026-05-10 in the pending list above.

- [x] **Fixed the Linux/glibc cgen failure.** Root cause was
      `cgen/cgen.c` `sub_1B2` storing `strcmp`'s result in a
      `char cmp` local. On platforms where `char` defaults to
      unsigned (gcc on Linux/arm64) the high bit was lost and the
      `cmp < 0` branch never fired, so the binary-search token
      lookup always returned -1. Every `[s` / `[u` (struct/union)
      directive in the intermediate code hit `parseStmt`'s default
      case and aborted with "Bad int. code". Same root cause as the
      earlier `p1: killed by signal 6` symptom. Fix: declare `cmp`
      as `int`. Verified by reproducing with a 3-line `.p1` then
      seeing the test job in `.github/workflows/container.yml` go
      green for the first time end-to-end.

- [x] **Built a RunCPM Docker image and switched the test job to use it.**
      `runcpm/Dockerfile` builds MockbaTheBorg/RunCPM v6.9 + a
      `runcpm-run` wrapper into a small ubuntu:24.04 image, published
      to `ghcr.io/ravn/hitech:runcpm-latest` by the new
      `.github/workflows/runcpm-image.yml` workflow on changes under
      `runcpm/`. The `container.yml` test job now pulls this image
      instead of cloning + building RunCPM from source on every CI
      run. Also useful as a standalone CP/M-emulator distribution:
      `docker run --rm -v "$PWD:/work" ghcr.io/ravn/hitech:runcpm-latest /work/foo.com`.

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
