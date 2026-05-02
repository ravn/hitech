# Source this from any shell to make `zc` find both the host tools
# (in Linux/Install/) and the Z80 target runtime (in runtime/).
#
# Usage from the repo root:    source runtime/env.sh
#
# Works in bash and zsh.

if [ -n "${BASH_SOURCE-}" ]; then
    _hitech_src=${BASH_SOURCE[0]}
elif [ -n "${ZSH_VERSION-}" ]; then
    _hitech_src=${(%):-%x}
else
    _hitech_src=$0
fi

HITECH_ROOT=$(cd "$(dirname "$_hitech_src")/.." && pwd)
unset _hitech_src

export PATH="$HITECH_ROOT/Linux/Install:$PATH"
export INCDIR80="$HITECH_ROOT/runtime/include80"
export LIBDIR80="$HITECH_ROOT/runtime/lib80"

echo "HITECH host tools: $HITECH_ROOT/Linux/Install"
echo "HITECH includes:   $INCDIR80"
echo "HITECH libraries:  $LIBDIR80"
