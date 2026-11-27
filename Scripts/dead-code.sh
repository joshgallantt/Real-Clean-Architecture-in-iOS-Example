#!/bin/sh
# Scans for unused code with Periphery, against the index of the last build.
#
#   Scripts/dead-code.sh            fail if there is dead code the baseline does not list
#   Scripts/dead-code.sh --accept   rewrite the baseline to what is there now
#
# Skips, without failing, when Periphery is not installed or nothing has been
# built yet: a hook that cannot run must not be a reason nobody can commit.

cd "$(git rev-parse --show-toplevel)" || exit 1

if ! command -v periphery >/dev/null 2>&1; then
    echo "dead-code: periphery is not installed (brew install periphery); skipping."
    exit 0
fi

if [ ! -d .build/dd/Index.noindex/DataStore ]; then
    echo "dead-code: no build index yet (run Scripts/test.sh --build); skipping."
    exit 0
fi

# The baseline is what was already there when the hook was added. Only findings
# it does not list fail a commit.
baseline=.periphery.baseline.json

if [ "$1" = "--accept" ]; then
    periphery scan --quiet --write-baseline "$baseline" >/dev/null
    echo "dead-code: baseline rewritten."
    exit 0
fi

exec periphery scan --quiet --baseline "$baseline"
