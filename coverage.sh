#!/usr/bin/env bash
#
# Measures how much of the production code the tests reach.
#
#   ./coverage.sh            measure and print the breakdown
#   ./coverage.sh --run      run the suite first, then measure
#   ./coverage.sh --badge    measure, then rewrite the badge in README.md
#
# Two things make the raw xccov report misleading, and both are handled here.
#
# SwiftPM builds each module as a static library, so a module's own code is
# linked into every test bundle that uses it and appears once per bundle in the
# report. Reading it per target therefore counts the same file several times and
# credits module code to whichever test binary contains it. This aggregates by
# source path instead, keeping the best figure seen for each file — a line
# covered by any suite is covered.
#
# And the report counts the test code too, which is nearly all executed by
# definition and would flatter the total. Only paths outside Tests/ and
# TestSupport/ count.

set -uo pipefail

DERIVED="${DERIVED:-.build/dd}"
README="README.md"

if [ "${1:-}" = "--run" ]; then
    ./test.sh || exit 1
fi

RESULT=$(/bin/ls -td "$DERIVED"/Logs/Test/*.xcresult 2>/dev/null | head -1)
if [ -z "$RESULT" ]; then
    echo "No test results in $DERIVED. Run ./coverage.sh --run first."
    exit 2
fi

REPORT=$(mktemp)
trap 'rm -f "$REPORT"' EXIT
if ! xcrun xccov view --report --json "$RESULT" > "$REPORT" 2>/dev/null; then
    echo "Could not read coverage from $RESULT."
    echo "AllTests must have codeCoverage enabled — see TestPlans/AllTests.xctestplan."
    exit 2
fi

python3 - "$REPORT" "$README" "${1:-}" <<'PY'
import collections, json, re, sys

report, readme, mode = sys.argv[1], sys.argv[2], sys.argv[3]

best = {}
for target in json.load(open(report))["targets"]:
    for f in target.get("files", []):
        seen = best.get(f["path"])
        if seen is None or f["coveredLines"] > seen["coveredLines"]:
            best[f["path"]] = f

def area(path):
    if "/Tests/" in path or "/TestSupport/" in path or "/.build/" in path:
        return None
    if re.search(r"/Sources/\w*DI/", path):  return "DI and wiring"
    if "/iPhone/" in path:                   return "composition root"
    if "/Sources/Domain/" in path:           return "domain"
    if "/Sources/Data/" in path:             return "data"
    if "/Library/" in path:                  return "library"
    if "/UI/" in path:                       return "presentation"
    return "other"

areas = collections.defaultdict(lambda: [0, 0, 0])
for path, f in best.items():
    name = area(path)
    if not name:
        continue
    bucket = areas[name]
    bucket[0] += f["coveredLines"]
    bucket[1] += f["executableLines"]
    bucket[2] += 1

covered = sum(a[0] for a in areas.values())
total = sum(a[1] for a in areas.values())
if not total:
    print("No production code in the report.")
    raise SystemExit(2)
percent = covered / total * 100

print(f"{'area':20} {'lines':>14}   {'':>6} files")
for name, (c, t, n) in sorted(areas.items(), key=lambda kv: -(kv[1][0] / kv[1][1] if kv[1][1] else 0)):
    if t:
        print(f"{name:20} {c:6}/{t:<6}  {c / t * 100:5.1f}%  {n:4}")
print(f"{'':20} {'':6} {'':6}  {'-' * 6}")
print(f"{'production':20} {covered:6}/{total:<6}  {percent:5.1f}%")

if mode != "--badge":
    raise SystemExit(0)

# Anything below half is red; the bands above it are the shields.io defaults.
colour = ("brightgreen" if percent >= 90 else
          "green" if percent >= 75 else
          "yellow" if percent >= 60 else
          "orange" if percent >= 50 else "red")
badge = (f"[![coverage](https://img.shields.io/badge/coverage-{percent:.0f}%25-{colour}"
         f")](#test-coverage)")

text = open(readme).read()
pattern = r"\[!\[coverage\]\(https://img\.shields\.io/badge/coverage-[^)]*\)\]\([^)]*\)"
if re.search(pattern, text):
    text = re.sub(pattern, badge, text, count=1)
    where = "updated"
else:
    lines = text.split("\n")
    lines.insert(1, "")
    lines.insert(2, badge)
    text = "\n".join(lines)
    where = "inserted"
open(readme, "w").write(text)
print(f"\nbadge {where} in {readme}: {percent:.0f}% ({colour})")
PY
