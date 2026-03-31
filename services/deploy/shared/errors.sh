#!/usr/bin/env bash
# MedinovAI Error Handling — medinovai-deploy
# Standard: medinovai-ai-standards/CODING_STANDARDS.md
# Source this file: source shared/errors.sh

set -euo pipefail

# ── Error Codes ──────────────────────────────────────────────────
E_UNKNOWN="MED-0000"
E_VALIDATION="MED-1001"
E_AUTH_FAILED="MED-2001"
E_NOT_FOUND="MED-3001"
E_SAFE_DEFAULT="MED-9999"

# ── Logging (HIPAA-safe: never log PHI) ──────────────────────────
mos_logError() {
    local mos_code="${1:-$E_UNKNOWN}"
    local mos_msg="${2:-Unexpected error}"
    local mos_correlationId="${3:-$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo unknown)}"
    echo "[ERROR] code=$mos_code correlation_id=$mos_correlationId message=$mos_msg" >&2
}

# ── Safe-Default Trap ────────────────────────────────────────────
mos_safeDefaultTrap() {
    mos_logError "$E_SAFE_DEFAULT" "SAFE_DEFAULT_TRIGGERED — script=$0 line=${BASH_LINENO[0]}"
    exit 1
}
trap mos_safeDefaultTrap ERR

# ── Validation Helper ────────────────────────────────────────────
mos_assertNotEmpty() {
    local mos_varName="$1"
    local mos_value="$2"
    if [[ -z "$mos_value" ]]; then
        mos_logError "$E_VALIDATION" "Required parameter '$mos_varName' is empty"
        return 1
    fi
}
