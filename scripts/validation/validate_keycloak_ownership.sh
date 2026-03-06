#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/keycloak-ownership.json"

RUNTIME="compose"
COMPOSE_MODE="platform"
MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --compose-mode) COMPOSE_MODE="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Keycloak ownership config missing: $CONFIG_FILE"
  exit 1
fi

if [[ -z "$MODE" ]]; then
  MODE="$(python3 - <<'PY' "$CONFIG_FILE"
import json, sys
cfg = json.load(open(sys.argv[1], "r", encoding="utf-8"))
print(cfg.get("policy", {}).get("default_mode", "warn"))
PY
)"
fi

if [[ "$MODE" != "warn" && "$MODE" != "enforce" ]]; then
  echo "ERROR: mode must be warn or enforce, got: $MODE"
  exit 1
fi

ISSUES=0

emit_issue() {
  local msg="$1"
  if [[ "$MODE" == "warn" ]]; then
    echo "WARN: $msg"
  else
    echo "ERROR: $msg"
    ISSUES=$((ISSUES + 1))
  fi
}

file_has_regex() {
  local file_path="$1"
  local pattern="$2"
  python3 - <<'PY' "$file_path" "$pattern"
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
pattern = sys.argv[2]
if not path.exists():
    raise SystemExit(1)
text = path.read_text(encoding="utf-8")
raise SystemExit(0 if re.search(pattern, text, re.MULTILINE) else 1)
PY
}

check_compose_platform() {
  local tier0="$REPO_ROOT/infra/docker/docker-compose.tier0-infra.yml"
  local tier1="$REPO_ROOT/infra/docker/docker-compose.tier1-security.yml"
  local dev="$REPO_ROOT/infra/docker/docker-compose.dev.yml"

  if [[ ! -f "$tier0" || ! -f "$tier1" || ! -f "$dev" ]]; then
    emit_issue "Expected compose files are missing for platform mode."
    return
  fi

  if ! file_has_regex "$tier0" "^\\s*keycloak:"; then
    emit_issue "Tier0 compose must define keycloak service in platform mode."
  fi

  if ! file_has_regex "$tier1" "KEYCLOAK_URL:\\s*http://medinovai-keycloak:8080"; then
    emit_issue "Tier1 compose should target Keycloak at http://medinovai-keycloak:8080."
  fi

  if ! file_has_regex "$dev" "^\\s*keycloak:"; then
    emit_issue "Dev compose currently has no keycloak service, expected platform baseline."
  fi
}

check_compose_standalone() {
  local security_compose="${SECURITY_SERVICE_COMPOSE_FILE:-}"
  if [[ -z "$security_compose" ]]; then
    emit_issue "SECURITY_SERVICE_COMPOSE_FILE is not set for compose.standalone validation."
    return
  fi
  if [[ ! -f "$security_compose" ]]; then
    emit_issue "SECURITY_SERVICE_COMPOSE_FILE does not exist: $security_compose"
    return
  fi
  if ! file_has_regex "$security_compose" "^\\s*keycloak:"; then
    emit_issue "Standalone mode expects keycloak service in security-service compose file."
  fi
}

check_k8s_platform() {
  local tier0_k="$REPO_ROOT/infra/kubernetes/services/tier0/kustomization.yaml"
  local tier1_k="$REPO_ROOT/infra/kubernetes/services/tier1/kustomization.yaml"
  local tier1_security="$REPO_ROOT/infra/kubernetes/services/tier1/security.yaml"

  if ! file_has_regex "$tier0_k" "^\\s*-\\s*keycloak\\.yaml\\s*$"; then
    emit_issue "Tier0 kustomization must include keycloak.yaml for platform k8s mode."
  fi

  if file_has_regex "$tier1_k" "^\\s*-\\s*keycloak\\.yaml\\s*$"; then
    emit_issue "Tier1 kustomization must not include keycloak.yaml (single-owner violation)."
  fi

  if ! file_has_regex "$tier1_security" "KEYCLOAK_URL"; then
    emit_issue "Tier1 security manifest is missing KEYCLOAK_URL."
  elif ! file_has_regex "$tier1_security" "http://keycloak\\.medinovai-data\\.svc\\.cluster\\.local:9080"; then
    emit_issue "Tier1 security KEYCLOAK_URL must point to tier0 Keycloak service DNS."
  fi
}

case "$RUNTIME" in
  compose)
    if [[ "$COMPOSE_MODE" == "platform" ]]; then
      check_compose_platform
    elif [[ "$COMPOSE_MODE" == "standalone" ]]; then
      check_compose_standalone
    else
      echo "ERROR: unknown compose mode: $COMPOSE_MODE"
      exit 1
    fi
    ;;
  k8s)
    check_k8s_platform
    ;;
  *)
    echo "ERROR: runtime must be compose or k8s"
    exit 1
    ;;
esac

if [[ "$ISSUES" -gt 0 ]]; then
  exit 1
fi

echo "Keycloak ownership validation passed (mode=$MODE, runtime=$RUNTIME, compose_mode=$COMPOSE_MODE)."
