#!/bin/sh
# Extracts the program output from the noise that RunCPM prints
# around it (CCP banners, prompts, the perl alarm "Alarm clock"
# line that fires when stdin runs dry). Trailing blank lines are
# stripped — RunCPM emits a couple of blanks between the program
# and the next CCP banner that aren't part of the program output.
#
# Usage:  extract-output.sh PROGNAME < raw-runcpm-output > clean-output
# PROGNAME must be the uppercase 8.3 filename without extension
# that the CCP echoes after the "A0>" prompt (e.g. HELLO, PRFMT).

set -eu

if [ $# -ne 1 ]; then
    echo "usage: $0 PROGNAME" >&2
    exit 64
fi
prog=$1

awk -v prog="$prog" '
    { gsub(/\r/, "") }

    # Hit a stop pattern while accumulating: turn off, drop the
    # boundary line itself.
    flag && (/^RunCPM Version/ || /^A0>/ || /^Alarm clock/) {
        flag = 0
        next
    }

    # Accumulate program output between markers.
    flag {
        buf = buf $0 "\n"
        next
    }

    # Start marker — the CCP echoes "A0>PROGNAME" right before
    # transferring control to the program.
    $0 == "A0>" prog {
        flag = 1
    }

    END {
        # Strip trailing blank lines that RunCPM emits between the
        # program and its next prompt. Keep a single trailing newline.
        sub(/\n+$/, "\n", buf)
        printf "%s", buf
    }
'
