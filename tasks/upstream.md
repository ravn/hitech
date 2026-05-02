# Upstream contribution plan

Upstream is **`ogdenpm/hitech`** (Mark Ogden, GitHub user `ogdenpm`):
<https://github.com/ogdenpm/hitech>. The local `upstream` remote is configured.

As of 2026-05-02, our `main` is **10 commits ahead** of `upstream/main` and
**0 behind**. Last upstream commit is `505c288` (zas4 fix, June 2025).

## Status

PR submitted with explicit user authorisation on 2026-05-02:

> **<https://github.com/ogdenpm/hitech/pull/5>** — open, awaiting maintainer review.
> Title: "macOS portability: replace negative platform gates with #ifdef CPM"
> 3 files changed, +47/-2.

Branch `upstream-prep` is pushed to `origin` (ravn/hitech) and serves as the
PR head. Tracking remains unset so a stray `git push` from the working tree
cannot accidentally target upstream. Three clean commits on top of
`upstream/main`:

```
1e027ca cgen/nikitin: document LIBRARY.HUF transcription bugs
d606e97 cpp: replace defined(unix) || defined(_WIN32) guard with #ifndef CPM
b386e50 enhuff: replace !unix && !_WIN32 guard with #if CPM
```

If the maintainer requests rebases or splits, do that on `upstream-prep` and
push again. Other open items (runtime/ vendoring, AGENTS.md/CLAUDE.md,
re-Huffman'ing LIBRARY.HUF) remain not-yet-discussed.

## Upstream-quality vs local-only

The session produced two distinct kinds of work:

- **Code/doc improvements that affect every contributor** — these belong upstream.
- **Local working notes per AGENT.md convention** — these are intentionally
  local to this fork.

| Commit    | Files                                        | Upstream? | Notes                                                      |
|-----------|----------------------------------------------|-----------|------------------------------------------------------------|
| `808eb09` | enhuff/enhuff.c, AGENTS.md, CLAUDE.md        | partial   | Just the enhuff `#if CPM` fix; AGENTS.md/CLAUDE.md TBD     |
| `79f2cfd` | merge commit                                 | no        | Merge artefact only                                        |
| `51d58ae` | tasks/todo.md, tasks/lessons.md              | no        | Local working notes per AGENT.md                           |
| `749bc9a` | cpp/cpp.c, tasks/todo.md                     | partial   | Just the cpp.c `#ifndef CPM` fix                           |
| `1b46df9` | cgen/nikitin/KNOWN_BUGS.md, tasks/todo.md    | partial   | The KNOWN_BUGS.md (no tasks bookkeeping)                   |
| `4aff476` | tasks/todo.md                                | no        | Local notes only                                           |
| `8a28af0` | runtime/                                     | maybe     | 244 KB of vendored agn453 dist; ask Mark before submitting |
| `afaf74a` | tasks/todo.md                                | no        | Local notes only                                           |
| `d7761c5` | tasks/todo.md                                | no        | Local notes only                                           |

## Recommended PRs (against `ogdenpm/hitech`)

**PR-1 — macOS portability fixes (highest value, smallest, zero-risk).**
Replace two negative platform tests with the project's positive `CPM`
convention. Apple clang does not predefine `unix`, so the originals
silently mis-gated on macOS (build error in enhuff, latent dead-code in
cpp). One-line C changes, no behaviour change on any existing platform.

Two clean cherry-picked commits:

```
enhuff: replace !unix && !_WIN32 guard with #if CPM
       (1 line in enhuff/enhuff.c)
cpp: replace defined(unix) || defined(_WIN32) guard with #ifndef CPM
       (1 line in cpp/cpp.c, with the latency analysis in the body)
```

**PR-2 — KNOWN_BUGS.md for `cgen/nikitin/LIBRARY.HUF`.**
Documents two one-character transcription errors (`sprintf.asm:21`,
`pnum.asm:56`) without modifying Nikitin's contributed `.HUF` archive.
Inert today (the working symbols come from `agn453/dist/LIBC.LIB`); only
matters to anyone unpacking `LIBRARY.HUF` directly.

One commit (clean cherry-pick): `cgen/nikitin/KNOWN_BUGS.md`.

**Optional / ask first — `runtime/` vendoring.**
244 KB of agn453's `dist/` headers + libraries + startup objects, with
provenance and `LICENSE.HITECH`. Useful as a reproducible cross-compile
runtime, but it's a large addition that duplicates the agn453 fork. Mark
may prefer fetch-at-build over vendoring, or may not want it at all.
**Recommend asking before opening a PR.** If accepted, also includes
`runtime/env.sh` and updates to AGENTS.md / CLAUDE.md.

**Probably not for upstream — `AGENTS.md` and `CLAUDE.md`.**
These were rewritten/created in this session for AI-agent orientation.
Mark may have his own preferred conventions, may not use AI agents, or
may want a different shape. Discuss before submitting.

**Definitely not for upstream — `tasks/todo.md` and `tasks/lessons.md`.**
These are this fork's working notes per the user's own `AGENT.md`
(itself untracked locally). Don't push.

## Mechanical plan when ready

```bash
# Prepare a clean branch with just the upstream-quality changes
git switch -c upstream-prep upstream/main
git cherry-pick --no-commit 808eb09 -- enhuff/enhuff.c
git commit -m "enhuff: replace !unix && !_WIN32 guard with #if CPM"
git cherry-pick --no-commit 749bc9a -- cpp/cpp.c
git commit -m "cpp: replace defined(unix) || defined(_WIN32) guard with #ifndef CPM"
git cherry-pick --no-commit 1b46df9 -- cgen/nikitin/KNOWN_BUGS.md
git commit -m "cgen/nikitin: document LIBRARY.HUF transcription bugs"

# Push to your fork on a feature branch and open the PR
git push origin upstream-prep
gh pr create --repo ogdenpm/hitech --base main --head ravn:upstream-prep \
    --title "macOS portability: convert negative platform gates to #ifdef CPM" \
    --body-file <(...)
```

This is a *plan*, not a script — confirm before executing, especially
the `gh pr create` step (cross-repo PR is a shared-state action).

## Open questions for the maintainer

1. Are the two C fixes (enhuff + cpp.c:1895) wanted? (High confidence yes.)
2. Is the KNOWN_BUGS.md addition welcome, or would Mark prefer to
   re-Huffman LIBRARY.HUF directly?
3. Any interest in vendoring the agn453 runtime under `runtime/`, or
   should that stay out-of-tree?
4. AI-agent files (AGENTS.md / CLAUDE.md) — yes, no, different shape?
