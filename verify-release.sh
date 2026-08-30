#!/usr/bin/env bash
#
# Proves the shipped app contains no test code.
#
#   ./verify-release.sh
#
# Three things have to be true, and this checks all three rather than trusting
# the first. The first two are structural and the third is evidence: a build
# system can be told to do the right thing and a manifest can be read wrongly,
# but a symbol either is in the binary or it is not.
#
#   1. No production target declares a dependency on a TestSupport product
#   2. keystone-swift agrees — its `testSupport` role is visible to tests alone
#   3. The archived binary contains no test-support symbols
#
# Run it before submitting, and in CI on the release configuration.

set -uo pipefail

PROJECT="CleanArchitecture.xcodeproj"
SCHEME="${SCHEME:-iPhone}"
ARCHIVE="${ARCHIVE:-.build/verify/iPhone.xcarchive}"

bold=$'\033[1m'; red=$'\033[31m'; green=$'\033[32m'; dim=$'\033[2m'; off=$'\033[0m'
[ -t 1 ] || { bold=""; red=""; green=""; dim=""; off=""; }

failed=0
step() { printf '%s%s%s\n' "$bold" "$1" "$off"; }
pass() { printf '  %s✓%s %s\n' "$green" "$off" "$1"; }
fail() { printf '  %s✗%s %s\n' "$red" "$off" "$1"; failed=1; }

# ── 1. Nothing production-side asks for test support ────────────────────────

step "Manifests"
offenders=$(
    for manifest in */*/Package.swift; do
        python3 - "$manifest" <<'PY'
import re, sys, pathlib
text = pathlib.Path(sys.argv[1]).read_text()
# Every target, with the kind of target it is and what it depends on.
for match in re.finditer(r'\.(testTarget|target)\(\s*\n\s*name: "(\w+)",\s*\n\s*dependencies: \[', text):
    kind, name = match.group(1), match.group(2)
    start = text.index("[", match.end() - 1)
    depth, i = 0, start
    while True:
        if text[i] == "[": depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0: break
        i += 1
    body = text[start:i]
    # A test target may depend on test support. A TestSupport target may too.
    # Anything else that does would carry it into the app.
    if kind == "testTarget" or name.endswith("TestSupport"):
        continue
    for used in re.findall(r'"(\w*TestSupport)"', body):
        print(f"{sys.argv[1]}: {name} depends on {used}")
PY
    done
)
if [ -n "$offenders" ]; then
    while read -r line; do fail "$line"; done <<< "$offenders"
else
    pass "no production target depends on a TestSupport product"
fi

# ── 2. The architecture checker agrees ──────────────────────────────────────

step "Architecture"
if command -v keystone-swift >/dev/null 2>&1; then
    if keystone-swift check --root . --no-colour 2>/dev/null | grep -q 'not-visible'; then
        fail "keystone-swift reports a production target reaching test support"
    else
        pass "keystone-swift reports no test support reachable from production"
    fi
else
    printf '  %s·%s keystone-swift not on PATH, skipped\n' "$dim" "$off"
fi

# ── 3. The binary itself ────────────────────────────────────────────────────

step "Archive"
rm -rf "$ARCHIVE"
if ! xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -archivePath "$ARCHIVE" \
        -quiet > .build/verify.log 2>&1; then
    fail "archive failed — see .build/verify.log"
    exit 1
fi

binary=$(find "$ARCHIVE/Products/Applications" -type f -perm +111 -name 'iPhone' | head -1)
[ -z "$binary" ] && { fail "no binary in the archive"; exit 1; }
pass "archived $(du -h "$binary" | cut -f1) binary"

# Swift mangles a module's name into every symbol it declares, so a linked
# TestSupport module cannot hide: its name is in the symbol table.
found=$(nm -u -j "$binary" 2>/dev/null; nm -j "$binary" 2>/dev/null)
leaked=$(printf '%s\n' "$found" | grep -oE '[0-9]+(TestSupport|AsyncTesting)' | sort -u)
if [ -n "$leaked" ]; then
    fail "test-support symbols in the shipped binary:"
    printf '      %s\n' $leaked
else
    pass "no test-support module symbols"
fi

doubles=$(printf '%s\n' "$found" | grep -cE '\b(Stub|Spy|Fake|InMemory|Dummy)[A-Z]' 2>/dev/null || true)
if [ "${doubles:-0}" -gt 0 ]; then
    fail "$doubles symbols look like test doubles"
    printf '%s\n' "$found" | grep -oE '(Stub|Spy|Fake|InMemory|Dummy)[A-Za-z]+' | sort -u | head -5 | sed 's/^/      /'
else
    pass "no symbols named like a test double"
fi

echo
if [ "$failed" -eq 0 ]; then
    echo "${green}${bold}Safe to ship${off}  ${dim}no test code reaches the binary${off}"
    exit 0
fi
echo "${red}${bold}Do not ship${off}"
exit 1
