#!/usr/bin/env bash
#
# Runs the tests and says what failed and why.
#
#   ./test.sh                    every test
#   ./test.sh unit               one tier — unit, acceptance or snapshot
#   ./test.sh Bag                one module, every tier of it
#   ./test.sh unit Wishlist      that tier, narrowed to matching targets
#   ./test.sh --build            build the app, no tests
#   ./test.sh --plans            list the test plans
#
# Full output goes to .test-logs/. The terminal gets a summary and, for
# failures, the errors that matter — usually enough to fix without opening a log.
#
# One xcodebuild invocation rather than one per target: the tiers are Xcode test
# plans in TestPlans/, so the whole suite shares a build and a simulator boot.
# Running the 48 targets separately spent eleven minutes rebuilding the same
# thing forty-eight times.

set -uo pipefail

PROJECT="CleanArchitecture.xcodeproj"
SCHEME="${SCHEME:-iPhone}"
SIMULATOR="${SIMULATOR:-iPhone 17}"
DERIVED="${DERIVED:-.build/dd}"
LOGS=".test-logs"
# One worker per performance core. Each worker is a simulator clone, so more of
# them than the machine can actually run at once buys queueing, not speed.
WORKERS="${WORKERS:-$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null || echo 4)}"

bold=$'\033[1m'; red=$'\033[31m'; green=$'\033[32m'; dim=$'\033[2m'; off=$'\033[0m'
[ -t 1 ] || { bold=""; red=""; green=""; dim=""; off=""; }

# Four plans describe the project; one per module sits beside its package.
plans() {
    { ls TestPlans/*.xctestplan; ls */*/*.xctestplan; } 2>/dev/null \
        | xargs -n1 basename | sed 's/\.xctestplan$//' | sort -u
}

path_of() {
    for candidate in "TestPlans/$1.xctestplan" */*/"$1.xctestplan"; do
        [ -f "$candidate" ] && { echo "$candidate"; return; }
    done
}

# A tier word or a module name picks a plan; anything else narrows within it.
plan_for() {
    case "$(echo "$1" | tr 'A-Z' 'a-z')" in
        all)        echo AllTests; return ;;
        unit)       echo UnitTests; return ;;
        acceptance) echo AcceptanceTests; return ;;
        snapshot)   echo SnapshotTests; return ;;
    esac
    plans | grep -ix "$1Tests" || plans | grep -ix "$1"
}

targets_in() {
    python3 -c "
import json
plan = json.load(open('$(path_of "$1")'))
print('\n'.join(t['target']['name'] for t in plan['testTargets']))"
}

explain() {
    local log="$1"
    grep -oE '[^/ ]+\.swift:[0-9]+:[0-9]+: error: .*' "$log" | sort -u | head -6
    grep -q 'Undefined symbols' "$log" && \
        grep -A2 'Undefined symbols' "$log" | grep -oE '"[^"]+"' | head -3
    grep -oE 'Test "[^"]+" recorded an issue.*' "$log" | head -5
    grep -A6 '^Failing tests:' "$log" | tail -n +2 | sed 's/^[[:space:]]*/failing: /' | head -6
    grep -oE 'encountered an error \([^)]*' "$log" | head -1
}

case "${1:-}" in
    --plans) plans; exit 0 ;;
esac

if [ "$(xcrun simctl list devices available | grep -cE "$SIMULATOR \(")" -eq 0 ]; then
    echo "${red}No simulator called '$SIMULATOR'.${off}"
    exit 2
fi

mkdir -p "$LOGS"

if [ "${1:-}" = "--build" ]; then
    echo "${bold}Building${off}"
    if xcodebuild build -project "$PROJECT" -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        -derivedDataPath "$DERIVED" -quiet > "$LOGS/build.log" 2>&1; then
        echo "  ${green}✓${off} $SCHEME"
        exit 0
    fi
    echo "  ${red}✗${off} $SCHEME"
    explain "$LOGS/build.log" | sed 's/^/      /'
    exit 1
fi

# Two runs against one simulator race over install and launch, and the failures
# that produces look exactly like real ones.
if pgrep -q xcodebuild; then
    echo "${red}xcodebuild is already running.${off} Two runs on one simulator produce"
    echo "failures that look real and are not. Wait for it, or set SIMULATOR to another device."
    exit 2
fi

plan="AllTests"
filters=()
for arg in "$@"; do
    resolved=$(plan_for "$arg")
    if [ -n "$resolved" ]; then plan="$resolved"; else filters+=("$arg"); fi
done

only=()
if [ ${#filters[@]} -gt 0 ]; then
    pattern=$(printf '%s|' "${filters[@]}"); pattern="${pattern%|}"
    while read -r target; do only+=("-only-testing:$target"); done \
        < <(targets_in "$plan" | grep -E "$pattern")
    if [ ${#only[@]} -eq 0 ]; then
        echo "Nothing in $plan matched."
        exit 2
    fi
fi

if [ ${#only[@]} -gt 0 ]; then count=${#only[@]}; else count=$(targets_in "$plan" | wc -l | tr -d ' '); fi
log="$LOGS/$plan.log"

echo "${bold}$plan${off}  $count target(s) on $SIMULATOR  ${dim}$log${off}"
started=$SECONDS

xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -testPlan "$plan" \
    -parallel-testing-enabled YES \
    -maximum-parallel-testing-workers "$WORKERS" \
    -parallelizeTargets \
    ${only[@]+"${only[@]}"} \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -derivedDataPath "$DERIVED" \
    -quiet \
    > "$log" 2>&1
status=$?
elapsed=$((SECONDS - started))

echo
if [ $status -eq 0 ]; then
    echo "${green}${bold}Passed${off}  ${dim}(${elapsed}s)${off}"
    exit 0
fi
echo "${red}${bold}Failed${off}  ${dim}(${elapsed}s)${off}"
explain "$log" | sed 's/^/  /'
exit 1
