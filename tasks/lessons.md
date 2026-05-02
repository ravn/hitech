# Lessons — corrections internalised during AI-agent work in this repo

Per `AGENT.md` §3 (Self-Improvement Loop). Each entry: the rule, why the user
asked for it (or what went wrong), and how to apply it. Keep entries terse;
this file is meant to be re-read at the start of future sessions.

---

## Communication style

**No compliments, no excuses, be concise, always show reasoning.**

Why: User explicitly asked on 2026-05-02. They want to follow my reasoning,
not be reassured by it.

How to apply: Lead user-facing text with the salient observations and the
inference, then the action. Skip filler openings ("Great question…", "Let
me…"). If I made a wrong call, fix it and move on — don't apologise, just
correct.

---

## Flag guesses explicitly

**State "I'm guessing X — should I verify?" instead of slipping unverified
claims into prose.**

Why: I made several unflagged guesses in early `AGENTS.md` drafts (asserted
`cpp.c` had a runtime bug without reproducing it, asserted `clang-format` is
run before commits without evidence, asserted `gcc` on macOS aliases to clang
without checking). User asked me to flag these explicitly.

How to apply: Before stating a fact in user-facing text or in a written file,
ask "did I verify this in this session, or am I inferring?" If the latter,
flag it. When in doubt, run the check or ask.

---

## Consult online docs when unclear

**For HI-TECH C 3.09 / Z80 / CP/M specifics not derivable from this repo,
web-search authoritative sources before guessing.**

Why: User authorised this on 2026-05-02 ("if unclear also study online
documentation"). Avoids stalling on details well-documented historically but
not present in this single repo.

How to apply: First check the repo (sources, READMEs, comments, mkpat test
inputs). If still unclear, web-search. Useful starting points:
`agn453/HI-TECH-Z80-C` (canonical maintained fork), the `HI-TECH C User's
Manual` PDF, `hi-tech.msx.click` wiki. Cite what was found, briefly. Still
flag doc-derived inferences vs. tested facts.

---

## Quote `=`-prefixed tokens in Bash commands

**Use `echo "==="` not `echo ===`.**

Why: This Mac runs zsh with default `EQUALS` option on. Unquoted `=cmd` is a
PATH-style command-lookup shortcut (`=ls` → `/bin/ls`), so `===` parses as
`=` + `==`, zsh searches `$PATH` for a literal `==`, fails, emits
`(eval):1: == not found`. The `(eval):1:` prefix is the Claude Code Bash-tool
harness wrapping commands in `zsh -c "eval ..."`. User's `~/.zshrc` is clean —
this is default zsh behaviour. They've chosen to keep `EQUALS` on; the burden
is on me to quote.

How to apply: Always quote separators starting with `=`. Or use `---`,
`###`, `:::` instead. The same applies to any unquoted argument starting
with `=`.

---

## Never `cp` over a symlink target without auditing

**Staging directories must hold real copies, not symlinks pointing back into
the source repo.**

Why: On 2026-05-02 I created
`/tmp/hitech-test/lib80/libc.lib → /Users/ravn/git/hitech/mkpat/test/libc80.lib`
as a "convenient symlink", then `cp /tmp/htc-dist/dist/LIBC.LIB
/tmp/hitech-test/lib80/libc.lib` to "upgrade" the staging area. `cp` followed
the symlink and silently overwrote three committed files in `mkpat/test/`
(real test inputs for `mkpat`'s FLIRT-pattern generation). Caught only by
`git status`. Restored via `git checkout HEAD -- <files>`.

How to apply:
- For staging: copy real files into the staging directory, never symlink to
  repo-tracked paths.
- After any `cp`/`mv` into a staging area, run `git status` to confirm the
  source repo wasn't touched.
- Be especially wary of "I'll just upgrade the staging dir" patterns — that's
  the moment the original symlink becomes a footgun.
- Symlinks to *generated* outputs (e.g. `Linux/Install/<tool>`) are fine; the
  hazard is symlinks to committed source files.

---

## Apply project-local AGENT.md conventions, not just my private memory

**When a repo has its own `AGENT.md` / `tasks/todo.md` / `tasks/lessons.md`
convention, write to those files in addition to (or instead of) my private
memory store.**

Why: On 2026-05-02 I had been recording lessons to
`~/.claude/projects/-Users-ravn-git-hitech/memory/feedback_*.md` (private to
me, cross-session) while ignoring the repo's `AGENT.md` directive to use
`tasks/lessons.md`. User pointed me back at `AGENT.md`. The repo wants to be
the source of truth for the project's collaboration rules so other agents and
human collaborators see the same conventions.

How to apply: At the start of any session in a new repo, check for
`AGENT.md`, `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, or `.github/copilot-
instructions.md`. Follow whatever convention they describe. Private memory is
a complement, not a substitute.

---

## Repo-specific facts to remember

- The canonical macro for the CP/M target is **`CPM`** (positive test). Use
  `#ifdef CPM` to gate CP/M-only code; use `#ifndef CPM` for modern-host-only
  code. Examples: `dehuff/dehuff.c:29`, `libr/libr.c:726`, `cgen/cgen.h:77`,
  `hishared/showVersion.h:9`. Do **not** introduce new negative tests like
  `#if !defined(unix) && !defined(_WIN32)` — Apple clang doesn't predefine
  `unix` so they silently misbehave.

- Decompilation parity with the original CP/M binaries is a stated project
  goal. `git log` is authoritative for whether a change was deliberate.
  `zas4/readme.md` lists deliberate deviations.

- `cgen/nikitin/{LIBRARY.HUF, CGEN.HUF, SOURCE.HUF}` are the bundled source
  archives. `LIBRARY.HUF` has runtime + library helpers; `CGEN.HUF` contains
  cgen's own decompiled source plus a real `STDIO.H`; `SOURCE.HUF` has
  cgen's C source named after disassembled offsets.

- `mkpat/test/{LIBC.LIB, libc80.lib, LIBOVR.LIB, crtcpm.obj, …}` are
  intentionally committed as inputs for `mkpat`'s FLIRT-pattern generator,
  not as a runtime bundle. The full HI-TECH C 3.09 runtime + headers come
  from `agn453/HI-TECH-Z80-C/dist/`.
