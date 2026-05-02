# HI-TECH C 3.09 runtime tree

This directory holds the **CP/M-80 / Z80 target runtime** that the locally
built host tools (`zc`, `cpp`, `p1`, `cgen`, `optim`, `zas`, `link`,
`objtohex`) need in order to produce a working `.com` file. The host tools
themselves are produced by `make` in `Linux/`; **this directory is the *target*
side and is not built — it is vendored as-is.**

## Provenance

All files here were copied verbatim from Tony Nicholson's consolidated
distribution of HI-TECH C 3.09:

- **Upstream:** <https://github.com/agn453/HI-TECH-Z80-C> — directory `dist/`
- **Maintainer:** Tony Nicholson <tony.nicholson@computer.org>
- **Snapshot taken:** 2026-05-02
- **Commit / tag:** snapshot of the upstream `master` branch as of the date
  above (no upstream tag was current at the time)

The upstream `dist/` is itself a consolidation of HI-TECH Software's
freeware v3.09 release plus subsequent community fixes. See `LICENSE.HITECH`
in this directory for the freeware grant from HI-TECH Software, and the
upstream repository for the change history of the post-3.09 fixes.

## License

> The HI-TECH Z80 CP/M C compiler V3.09 is provided free of charge for any
> use, private or commercial, strictly as-is. No warranty or product
> support is offered or implied. You may use this software for whatever you
> like, providing you acknowledge that the copyright to this software
> remains with HI-TECH Software.

Original text retained as `LICENSE.HITECH` alongside this README. Copyright
in the C compiler itself remains with HI-TECH Software (the company is
defunct; the freeware grant on the Wayback Machine is canonical, see
<https://web.archive.org/web/20000301031041/http://www.hitech.com.au/>).

## Contents

```
runtime/
├── LICENSE.HITECH      copy of the upstream HI-TECH freeware grant
├── README.md           this file
├── include80/          22 standard headers (#include search path)
└── lib80/              runtime libraries + startup objects (linker inputs)
```

### `include80/` — standard headers (22 files)

`ASSERT.H`, `CONIO.H`, `CPM.H`, `CTYPE.H`, `EXEC.H`, `FLOAT.H`, `HITECH.H`,
`LIMITS.H`, `MATH.H`, `OVERLAY.H`, `SETJMP.H`, `SIGNAL.H`, `STAT.H`,
`STDARG.H`, `STDDEF.H`, `STDINT.H`, `STDIO.H`, `STDLIB.H`, `STRING.H`,
`SYS.H`, `TIME.H`, `UNIXIO.H`.

### `lib80/` — libraries and startup objects

| File         | Purpose                                                |
|--------------|--------------------------------------------------------|
| `LIBC.LIB`   | Standard C runtime (stdio, string, memory, …)          |
| `LIBF.LIB`   | Floating-point routines (used when `-LF` is passed)    |
| `LIBOVR.LIB` | Overlay support (`#include <overlay.h>`)               |
| `CRTCPM.OBJ` | CP/M startup with command-line argument parsing (`-R`) |
| `DRTCPM.OBJ` | Debug startup variant                                  |
| `NRTCPM.OBJ` | Default ("no-getargs") CP/M startup                    |
| `RRTCPM.OBJ` | Reentrant runtime startup variant                      |

Files **not** copied from upstream `dist/`:

- `*.COM` — the original CP/M binaries of the compiler tools themselves;
  not needed when cross-compiling from a modern host using the locally
  built versions in `Linux/Install/`.
- `LIBCORIG.LIB`, `LIBFORIG.LIB` — pristine pre-fix originals; useful for
  diffing only. Fetch from upstream if you need them.
- `*.HUF` archives — Huffman-bundled source archives; the equivalents for
  this project's own work live in `cgen/nikitin/*.HUF`.

## Usage

After building the host tools (`make` in `Linux/`), source the env helper from
the repo root:

```bash
source runtime/env.sh
zc hello.c                  # produces hello.com
```

`env.sh` exports three variables:

- `PATH` is prefixed with `Linux/Install/` so `zc` can locate `cpp`, `p1`,
  `cgen`, `optim`, `zas`, `link`, `objtohex`, `cref`.
- `INCDIR80` points at `runtime/include80/` (used by `cpp` for `<...>` and
  `"..."` includes).
- `LIBDIR80` points at `runtime/lib80/` (used by `link` for the runtime
  libraries and by `zc` to find the right startup `.OBJ`).

Alternative: `zc` also accepts `HITECH=<root>` as a single env var that is
expanded internally to `<root>/bin`, `<root>/include80`, `<root>/lib80`.
We avoid that here because there is no `runtime/bin/` — the host tools
live in `Linux/Install/`, separate from the Z80 target tree.

The startup-object selection matches `zc`'s flags:

- default: `lib80/NRTCPM.OBJ`
- `zc -R`: `lib80/CRTCPM.OBJ` (so `argc`/`argv` are populated from the CP/M command line)
- `zc -D`: `lib80/DRTCPM.OBJ`

Verified end-to-end on macOS (Apple clang 21.0.0) on 2026-05-02:
`printf("hello, z80!\n")` compiled via this runtime ran correctly under
RunCPM v6.7. See `tasks/todo.md` Done section.

## Refreshing from upstream

The snapshot is intentionally pinned. To refresh:

```bash
git clone https://github.com/agn453/HI-TECH-Z80-C /tmp/htc-dist
cp -p /tmp/htc-dist/dist/*.H        runtime/include80/
cp -p /tmp/htc-dist/dist/LIBC.LIB \
      /tmp/htc-dist/dist/LIBF.LIB \
      /tmp/htc-dist/dist/LIBOVR.LIB \
      /tmp/htc-dist/dist/CRTCPM.OBJ \
      /tmp/htc-dist/dist/DRTCPM.OBJ \
      /tmp/htc-dist/dist/NRTCPM.OBJ \
      /tmp/htc-dist/dist/RRTCPM.OBJ \
                                    runtime/lib80/
cp -p /tmp/htc-dist/LICENSE         runtime/LICENSE.HITECH
```

Then update the "Snapshot taken" date above and commit.
