#!/usr/bin/env bash
# Smoke Tests — medinovai-deploy
# Run: bash tests/test_smoke.sh
set -euo pipefail

E_PASS=0
E_FAIL=0
E_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mos_assert() {
    local mos_desc="$1"
    local mos_cmd="$2"
    if eval "$mos_cmd" >/dev/null 2>&1; then
        echo "  ✅ $mos_desc"
        ((E_PASS++))
    else
        echo "  ❌ $mos_desc"
        ((E_FAIL++))
    fi
}

echo "═══ Smoke Tests: medinovai-deploy ═══"
echo ""

echo "── Project Structure ──"
mos_assert "CLAUDE.md exists"              "[[ -f $E_ROOT/CLAUDE.md ]]"
mos_assert "SECURITY.md exists"            "[[ -f $E_ROOT/SECURITY.md ]]"
mos_assert ".gitignore exists"             "[[ -f $E_ROOT/.gitignore ]]"
mos_assert "medinovai.manifest.yaml exists" "[[ -f $E_ROOT/medinovai.manifest.yaml ]]"
mos_assert "CONTRIBUTING.md exists"        "[[ -f $E_ROOT/CONTRIBUTING.md ]]"
mos_assert "CHANGELOG.md exists"           "[[ -f $E_ROOT/CHANGELOG.md ]]"

echo ""
echo "── Error Module ──"
mos_assert "shared/errors.sh exists"       "[[ -f $E_ROOT/shared/errors.sh ]]"
mos_assert "errors.sh is sourceable"       "bash -n $E_ROOT/shared/errors.sh"

echo ""
echo "── .gitignore Safety ──"
mos_assert ".env in .gitignore"            "grep -q '.env' $E_ROOT/.gitignore"

echo ""
echo "═══ Results: $E_PASS passed, $E_FAIL failed ═══"
[[ $E_FAIL -eq 0 ]] && exit 0 || exit 1
