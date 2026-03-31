#!/bin/bash
set -e
REG=ghcr.io/myonsite-healthcare

SERVICES=(
  "medinovai-atlas-engine"
  "medinovai-canary-rollout-orchestrator"
  "medinovai-cds"
  "medinovai-clinical-decision-support"
  "medinovai-configuration-management"
  "medinovai-data-lake-loader"
  "medinovai-developer-portal"
  "medinovai-devops-telemetry"
  "medinovai-edge-cache-cdn"
  "medinovai-etl-designer"
  "medinovai-feature-flag-console"
  "medinovai-governance-templates"
  "medinovai-guideline-updater"
  "medinovai-knowledge-graph"
  "medinovai-multimodal-ui-shell"
  "medinovai-patient-services"
  "medinovai-policy-diff-watcher"
  "medinovai-prompt-vault"
  "medinovai-qa-agent-builder"
  "medinovai-risk-management"
  "medinovai-task-kanban"
  "medinovaios"
)

for svc in "${SERVICES[@]}"; do
  DIR="/tmp/fix-${svc}"
  mkdir -p "$DIR"
  
  # Extract main.py and requirements.txt from image
  CID=$(docker create "${REG}/${svc}:latest" 2>/dev/null)
  docker cp "${CID}:/app/main.py" "${DIR}/main.py" 2>/dev/null || true
  docker cp "${CID}:/app/requirements.txt" "${DIR}/requirements.txt" 2>/dev/null || true
  docker rm "$CID" > /dev/null 2>&1 || true

  # Apply common fixes with Python
  python3 - "${DIR}/main.py" << 'PYEOF'
import sys, re
path = sys.argv[1]
try:
    code = open(path).read()
    # Fix: status.HTTP_201_CREATED etc → integer literals
    code = re.sub(r'status_code=status\.HTTP_(\d+)_\w+', lambda m: f'status_code={m.group(1)}', code)
    # Fix: status.HTTP_201_CREATED in list of attributes
    code = re.sub(r'\bstatus\.HTTP_(\d+)_\w+\b', lambda m: m.group(1), code)
    open(path, 'w').write(code)
except Exception as e:
    print(f"  Skip fix: {e}")
PYEOF

  # Ensure prometheus_client in requirements
  grep -q "prometheus_client" "${DIR}/requirements.txt" 2>/dev/null || echo "prometheus_client>=0.18.0" >> "${DIR}/requirements.txt"

  # Create clean Dockerfile
  cat > "${DIR}/Dockerfile" << 'DFEOF'
FROM python:3.12-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=5 \
  CMD curl -sf http://localhost:8080/health || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
DFEOF

  # Build and tag
  docker build -t "${REG}/${svc}:latest" "${DIR}" > /tmp/build-${svc}.log 2>&1 && \
    echo "✓ $svc" || echo "✗ $svc (see /tmp/build-${svc}.log)"
done

echo "=== All AI-gen service fixes complete ==="
