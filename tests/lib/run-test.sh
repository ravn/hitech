#!/bin/sh
# Runs one already-compiled test: invokes the .com inside the
# RunCPM Docker image, extracts the program output, diffs against
# the .expected file. Prints PASS/FAIL and exits accordingly.
#
# Usage:  run-test.sh BASENAME
#   - BASENAME.com must exist in $PWD
#   - BASENAME.expected must exist in $PWD
# Env:
#   RUNCPM_IMG  override the runcpm image (default ghcr.io/ravn/hitech:runcpm-latest)

set -eu

if [ $# -ne 1 ]; then
    echo "usage: $0 BASENAME" >&2
    exit 64
fi
prog=$1
upper=$(echo "$prog" | tr a-z A-Z)
img=${RUNCPM_IMG:-ghcr.io/ravn/hitech:runcpm-latest}

green=$(printf '\033[32m')
red=$(printf '\033[31m')
reset=$(printf '\033[0m')

docker run --rm -v "$PWD:/work" "$img" "/work/$prog.com" > "$prog.raw" 2>&1
./lib/extract-output.sh "$upper" < "$prog.raw" > "$prog.actual"

if diff -u "$prog.expected" "$prog.actual" > /dev/null; then
    printf '%sPASS%s %s\n' "$green" "$reset" "$prog"
    exit 0
fi

printf '%sFAIL%s %s\n' "$red" "$reset" "$prog"
echo "  --- expected ---"
sed 's/^/    /' "$prog.expected"
echo "  --- actual ---"
sed 's/^/    /' "$prog.actual"
echo "  --- runcpm raw ---"
sed 's/^/    /' "$prog.raw"
exit 1
