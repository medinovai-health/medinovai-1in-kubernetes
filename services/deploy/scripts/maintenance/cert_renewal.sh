#!/usr/bin/env bash
# ─── cert_renewal.sh ──────────────────────────────────────────────────────────
# Check certificate expiry and renew if needed.
#
# Usage:
#   bash scripts/maintenance/cert_renewal.sh --check-only
#   bash scripts/maintenance/cert_renewal.sh --renew
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

CHECK_ONLY=false
RENEW=false
WARNING_DAYS=30
CRITICAL_DAYS=7

while [[ $# -gt 0 ]]; do
    case $1 in
        --check-only)       CHECK_ONLY=true; shift ;;
        --renew)            RENEW=true; shift ;;
        --warning-days)     WARNING_DAYS="$2"; shift 2 ;;
        *)                  echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Certificate Health Check                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ISSUES=0

check_domain_cert() {
    local domain="$1"

    if ! command -v openssl &>/dev/null; then
        echo "  ⚠ openssl not available — cannot check $domain"
        return 0
    fi

    local expiry_date
    expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "")

    if [ -z "$expiry_date" ]; then
        echo "  ⚠ $domain — could not retrieve certificate"
        return 0
    fi

    local expiry_epoch
    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry_date" +%s 2>/dev/null || echo "0")
    local now_epoch
    now_epoch=$(date +%s)
    local days_remaining=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [ "$days_remaining" -lt "$CRITICAL_DAYS" ]; then
        echo "  ✗ $domain — CRITICAL: expires in $days_remaining days ($expiry_date)"
        ISSUES=$((ISSUES + 1))
    elif [ "$days_remaining" -lt "$WARNING_DAYS" ]; then
        echo "  ⚠ $domain — WARNING: expires in $days_remaining days ($expiry_date)"
        ISSUES=$((ISSUES + 1))
    else
        echo "  ✓ $domain — OK: expires in $days_remaining days ($expiry_date)"
    fi
}

echo "▸ Checking K8s cert-manager certificates..."
if command -v kubectl &>/dev/null; then
    kubectl get certificates -A -o json 2>/dev/null | python3 -c "
import json, sys
from datetime import datetime, timezone

try:
    certs = json.load(sys.stdin)
    for cert in certs.get('items', []):
        name = cert['metadata']['name']
        ns = cert['metadata']['namespace']
        conditions = cert.get('status', {}).get('conditions', [])
        ready = any(c['type'] == 'Ready' and c['status'] == 'True' for c in conditions)
        renewal = cert.get('status', {}).get('renewalTime', 'unknown')
        not_after = cert.get('status', {}).get('notAfter', 'unknown')
        status = '✓' if ready else '✗'
        print(f'  {status} {ns}/{name} — expires: {not_after}, renewal: {renewal}')
except Exception as e:
    print(f'  Could not parse certificates: {e}')
" 2>/dev/null || echo "  K8s not configured — skipping cert-manager check"
else
    echo "  kubectl not available — skipping K8s certificate check"
fi

echo ""
echo "▸ Checking domain certificates..."
CERT_CONFIG="${CERT_CONFIG:-$(dirname "$0")/../../config/domains.txt}"
DOMAINS=()
if [ -f "$CERT_CONFIG" ]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        DOMAINS+=("$line")
    done < "$CERT_CONFIG"
fi

if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "  No domains configured for checking. Add domains to this script."
else
    for domain in "${DOMAINS[@]}"; do
        check_domain_cert "$domain"
    done
fi

echo ""
if [ "$ISSUES" -gt 0 ]; then
    echo "ALERT: $ISSUES certificate(s) need attention!"
    if $RENEW; then
        echo ""
        echo "▸ Triggering certificate renewal..."
        if command -v kubectl &>/dev/null; then
            echo "  Renewing cert-manager certificates..."
            kubectl get certificates -A --no-headers 2>/dev/null | while read -r ns name rest; do
                echo "  Renewing $ns/$name..."
                kubectl cert-manager renew "$name" -n "$ns" 2>/dev/null || \
                    echo "  ⚠ Could not renew $ns/$name (cert-manager CLI may not be installed)"
            done
        fi
        if command -v aws &>/dev/null; then
            echo "  Checking AWS ACM certificates..."
            aws acm list-certificates --query 'CertificateSummaryList[?Status==`PENDING_VALIDATION`]' \
                --output text 2>/dev/null || echo "  ⚠ AWS ACM check failed"
        fi
    fi
    exit 2
else
    echo "✓ All certificates healthy."
fi
