#!/bin/bash

#####################################################################
# Setup Ollama Models for Validation
# Pull and verify 5 models for deployment validation
#####################################################################

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1"
}

log "Setting up Ollama models for validation..."

# Define required models
MODELS=(
    "deepseek-coder:33b"
    "qwen2.5:72b"
    "llama3.1:70b"
    "meditron:7b"
    "codellama:34b"
)

# Check if Ollama is running
if ! ollama list > /dev/null 2>&1; then
    echo "❌ Ollama is not running. Please start Ollama first."
    exit 1
fi

log_success "Ollama is running"

# Pull each model if not already present
for model in "${MODELS[@]}"; do
    log "Checking model: $model"
    if ollama list | grep -q "^${model}"; then
        log_success "Model $model already available"
    else
        log "Pulling model: $model (this may take a while)..."
        ollama pull "$model"
        log_success "Model $model pulled successfully"
    fi
done

log ""
log "Available models for validation:"
for model in "${MODELS[@]}"; do
    log "  ✅ $model"
done

log_success "All Ollama models are ready for validation"

exit 0

