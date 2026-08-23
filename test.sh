#!/usr/bin/env bash
#
# Runs the test suites and says which ones failed and why.
#
#   ./test.sh                 every test scheme
#   ./test.sh Wishlist Bag    only schemes whose name contains one of these
#   ./test.sh --build         build the app, no tests
#   ./test.sh --list          show the schemes without running anything
#
# Each scheme's full output goes to .test-logs/<scheme>.log. The terminal gets a
# line per scheme and, for anything that failed, the first few errors — which is
# almost always enough to know what to fix without opening a log at all.
#
# Two things make this quicker than running xcodebuild by hand per scheme: the
# simulator is booted once up front rather than per run, and every scheme shares
# one derived-data directory, so only the first build is a cold one.

set -uo pipefail

PROJECT="CleanArchitecture.xcodeproj"
SIMULATOR="${SIMULATOR:-iPhone 17}"
DERIVED="${DERIVED:-.build/dd}"
LOGS=".test-logs"

bold=$'\033[1m'; red=$'\033[31m'; green=$'\033[32m'; dim=$'\033[2m'; off=$'\033[0m'
[ -t 1 ] || { bold=""; red=""; green=""; dim=""; off=""; }

schemes() {
    xcodebuild -list -project "$PROJECT" 2>/dev/null \
        | sed -n '/Schemes:/,$p' | tail -n +2 | tr -d ' ' | grep -E 'Tests$'
}

# The first error lines are the useful ones; the rest are usually the same
# mistake seen from further away.
explain() {
    local log="$1"
    grep -oE '[^/]+\.swift:[0-9]+:[0-9]+: error: .*' "$log" | sort -u | head -4
    grep -q 'Undefined symbols' "$log" && \
        grep -A2 'Undefined symbols' "$log" | grep -oE '"[^"]+"' | head -2
    grep -oE '✘ Test "[^"]+" recorded an issue.*' "$log" | head -3
    grep -oE 'encountered an error \([^)]*' "$log" | head -1
    # `-quiet` keeps the per-test output out of the log, but the runner still
    # names what failed at the end, and a snapshot mismatch says so.
    grep -A4 '^Failing tests:' "$log" | tail -n +2 | sed 's/^[[:space:]]*/failing: /' | head -4
    grep -oE 'Snapshot does not match reference.*' "$log" | head -1
}

# The destination is given by name, not by resolving it to an identifier here.
#
# There are five simulators called "iPhone 17" on this machine, one per runtime,
# and picking the first is not picking the one xcodebuild would. Snapshot
# references recorded against one device do not match another, so every snapshot
# suite failed — which looked like twelve broken tests and was one wrong device.
# xcodebuild keeps the device booted between runs anyway, so nothing is lost.
devices() {
    xcrun simctl list devices available | grep -cE "$SIMULATOR \\("
}

run() {
    local action="$1" scheme="$2" log="$LOGS/$scheme.log"
    xcodebuild "$action" \
        -project "$PROJECT" \
        -scheme "$scheme" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        -derivedDataPath "$DERIVED" \
        -quiet \
        > "$log" 2>&1
}

case "${1:-}" in
    --list) schemes; exit 0 ;;
esac

mkdir -p "$LOGS"
[ "$(devices)" -eq 0 ] && { echo "${red}No simulator called '$SIMULATOR'.${off}"; exit 2; }

if [ "${1:-}" = "--build" ]; then
    echo "${bold}Building${off}"
    if run build iPhone; then
        echo "  ${green}✓${off} iPhone"
        exit 0
    fi
    echo "  ${red}✗${off} iPhone"
    explain "$LOGS/iPhone.log" | sed 's/^/      /'
    exit 1
fi

selected=$(schemes)
if [ "$#" -gt 0 ]; then
    pattern=$(printf '%s|' "$@"); pattern="${pattern%|}"
    selected=$(echo "$selected" | grep -E "$pattern")
fi
[ -z "$selected" ] && { echo "No schemes matched."; exit 2; }

total=$(echo "$selected" | wc -l | tr -d ' ')
# Two xcodebuild runs driving one simulator race over install and launch, and
# the failures that produces look exactly like real ones. Twelve snapshot suites
# "failed" that way once; every one passed alone.
if pgrep -q xcodebuild; then
    echo "${red}xcodebuild is already running.${off} Two runs on one simulator produce"
    echo "failures that look real and are not. Wait for it, or set SIMULATOR to another device."
    exit 2
fi

echo "${bold}$total scheme(s) on $SIMULATOR${off}  ${dim}logs in $LOGS/${off}"
echo

failed=()
index=0
started=$SECONDS
while read -r scheme; do
    index=$((index + 1))
    printf '  %2d/%s  %-36s' "$index" "$total" "$scheme"
    if run test "$scheme"; then
        printf '%s✓%s\n' "$green" "$off"
    else
        printf '%s✗%s\n' "$red" "$off"
        failed+=("$scheme")
    fi
done <<< "$selected"

echo
elapsed=$((SECONDS - started))
if [ ${#failed[@]} -eq 0 ]; then
    echo "${green}${bold}All $total passed${off}  ${dim}(${elapsed}s)${off}"
    exit 0
fi

echo "${red}${bold}${#failed[@]} of $total failed${off}  ${dim}(${elapsed}s)${off}"
for scheme in "${failed[@]}"; do
    echo
    echo "  ${bold}$scheme${off}  ${dim}$LOGS/$scheme.log${off}"
    explain "$LOGS/$scheme.log" | sed 's/^/      /'
done
exit 1
