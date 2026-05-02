#!/usr/bin/env bash
# Health check — run this when you sit back down at the project.
#
# What it does (in order):
#   1. Host build:    confirms Linux/Install/ has all 18 host tools.
#   2. Runtime tree:  confirms runtime/include80 + runtime/lib80 are present.
#   3. Smoke test:    runs `zc hello.c` end-to-end and checks the .com
#                     starts with the expected HI-TECH crt prelude.
#   4. RunCPM:        if /Users/ravn/git/RunCPM/RunCPM/RunCPM exists,
#                     actually executes the .com and checks the printed
#                     line.
#   5. Git state:     branch, ahead/behind origin and (if configured)
#                     upstream, dirty working tree, unpushed branches.
#   6. PR #5:         if `gh` is on PATH and you're authenticated, prints
#                     the merged/open state of ogdenpm/hitech#5 and the
#                     last reviewer comment, if any.
#
# Each step prints PASS / FAIL / SKIP. Exits non-zero if any FAIL.

set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

PASS=$'\033[32m✓\033[0m'
FAIL=$'\033[31m✗\033[0m'
SKIP=$'\033[33m–\033[0m'
fails=0

step() { printf '%s  %s\n' "$1" "$2"; }
note() { printf '   %s\n' "$1"; }

# ---------------------------------------------------------------- 1. host build
expected_tools=(cgen cpp cref dehuff dump enhuff hidump hidump2 libr libr4 link
                mkpat objtohex optim p1 zas zas4 zc)
missing=()
for t in "${expected_tools[@]}"; do
    [ -x "Linux/Install/$t" ] || missing+=("$t")
done
if [ ${#missing[@]} -eq 0 ]; then
    step "$PASS" "host build — Linux/Install/ has all 18 tools"
else
    step "$FAIL" "host build — missing: ${missing[*]}"
    note "fix: cd Linux && make"
    fails=$((fails + 1))
fi

# ---------------------------------------------------------------- 2. runtime tree
hdr_count=$(find runtime/include80 -maxdepth 1 -name '*.H' 2>/dev/null | wc -l | tr -d ' ')
lib_count=$(find runtime/lib80 -maxdepth 1 \( -name '*.LIB' -o -name '*.OBJ' \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$hdr_count" = "22" ] && [ "$lib_count" = "7" ]; then
    step "$PASS" "runtime tree — 22 headers + 7 libs/objs in runtime/"
else
    step "$FAIL" "runtime tree — got $hdr_count headers (want 22), $lib_count libs/objs (want 7)"
    note "see runtime/README.md for refresh instructions"
    fails=$((fails + 1))
fi

# ---------------------------------------------------------------- 3. smoke test
work=$(mktemp -d -t hitech-check.XXXXXX)
trap 'rm -rf "$work"' EXIT
cat > "$work/hello.c" <<'EOF'
#include <stdio.h>
int main(void) { printf("check passed\n"); return 0; }
EOF
if [ -x Linux/Install/zc ] && [ -d runtime/include80 ] && [ -d runtime/lib80 ]; then
    if ( cd "$work" && \
         PATH="$ROOT/Linux/Install:$PATH" \
         INCDIR80="$ROOT/runtime/include80" \
         LIBDIR80="$ROOT/runtime/lib80" \
         "$ROOT/Linux/Install/zc" hello.c ) >/dev/null 2>&1 \
       && [ -f "$work/hello.com" ]; then
        # Sanity check: HI-TECH crt0 always embeds the "Compiled with Hi-Tech C"
        # signature near the start of the .com (so the .com identifies itself
        # to the user when dumped). If that's there, the link succeeded against
        # one of the runtime CRTs (CRTCPM, NRTCPM, DRTCPM, or RRTCPM).
        if grep -aq 'Compiled with Hi-Tech C' "$work/hello.com"; then
            sz=$(stat -f %z "$work/hello.com" 2>/dev/null || stat -c %s "$work/hello.com")
            step "$PASS" "smoke test — zc hello.c -> $sz byte .com with HI-TECH signature"
        else
            step "$FAIL" "smoke test — .com produced but no HI-TECH signature found"
            note "first 32 bytes: $(head -c 32 "$work/hello.com" | xxd -p)"
            fails=$((fails + 1))
        fi
    else
        step "$FAIL" "smoke test — zc invocation or .com production failed"
        note "rerun by hand: source runtime/env.sh; zc hello.c"
        fails=$((fails + 1))
    fi
else
    step "$SKIP" "smoke test — host tools or runtime/ not built"
fi

# ---------------------------------------------------------------- 4. RunCPM
RUNCPM_DIR=${RUNCPM_DIR:-/Users/ravn/git/RunCPM/RunCPM}
if [ -x "$RUNCPM_DIR/RunCPM" ] && [ -f "$work/hello.com" ]; then
    cp "$work/hello.com" "$RUNCPM_DIR/A/0/CHECK.COM" 2>/dev/null
    out=$(cd "$RUNCPM_DIR" && printf 'CHECK\r\n' | perl -e 'alarm 5; exec @ARGV' ./RunCPM 2>&1)
    rm -f "$RUNCPM_DIR/A/0/CHECK.COM"
    if printf '%s' "$out" | grep -q 'check passed'; then
        step "$PASS" "RunCPM — hello.com runs and prints the expected line"
    else
        step "$FAIL" "RunCPM — emulator did not print 'check passed'"
        note "last 5 lines of output:"
        printf '%s' "$out" | tail -5 | sed 's/^/     /'
        fails=$((fails + 1))
    fi
else
    step "$SKIP" "RunCPM — emulator not at $RUNCPM_DIR (set RUNCPM_DIR to override)"
fi

# ---------------------------------------------------------------- 5. git state
branch=$(git rev-parse --abbrev-ref HEAD)
dirty_msg=""
if ! git diff --quiet HEAD -- 2>/dev/null; then
    dirty_msg=" (dirty working tree)"
fi
ahead_origin=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "?")
behind_origin=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo "?")
upstream_state=""
if git rev-parse --verify upstream/main >/dev/null 2>&1; then
    ahead_up=$(git rev-list --count "upstream/main..HEAD" 2>/dev/null)
    behind_up=$(git rev-list --count "HEAD..upstream/main" 2>/dev/null)
    upstream_state="; ahead $ahead_up / behind $behind_up of upstream/main"
fi
step "$PASS" "git — on '$branch', ahead $ahead_origin / behind $behind_origin of origin$upstream_state$dirty_msg"

# unpushed local branches
unpushed=$(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads/ \
    | awk '$2 == "" {print $1}' | grep -v "^$branch$" || true)
if [ -n "$unpushed" ]; then
    note "local-only branches (no upstream tracking): $(echo $unpushed | tr '\n' ' ')"
fi

# ---------------------------------------------------------------- 6. PR #5
if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        pr_json=$(gh pr view 5 --repo ogdenpm/hitech \
            --json state,mergedAt,reviewDecision,comments 2>/dev/null || true)
        if [ -n "$pr_json" ]; then
            pr_state=$(printf '%s' "$pr_json" | python3 -c \
              'import json,sys;d=json.load(sys.stdin);print(d.get("state",""),d.get("reviewDecision") or "")' \
              2>/dev/null)
            comments=$(printf '%s' "$pr_json" | python3 -c \
              'import json,sys;d=json.load(sys.stdin);c=d.get("comments",[]);print(len(c))' \
              2>/dev/null)
            step "$PASS" "PR #5 — $pr_state, $comments comment(s)"
            note "view: gh pr view 5 --repo ogdenpm/hitech"
        else
            step "$SKIP" "PR #5 — gh pr view 5 returned no data"
        fi
    else
        step "$SKIP" "PR #5 — gh not authenticated; run 'gh auth login'"
    fi
else
    step "$SKIP" "PR #5 — gh not on PATH"
fi

# ----------------------------------------------------------------- exit code
echo
if [ "$fails" -eq 0 ]; then
    echo "All checks passed."
    exit 0
else
    echo "$fails check(s) failed."
    exit 1
fi
