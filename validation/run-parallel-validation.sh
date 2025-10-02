#!/bin/bash

# 5-Model Parallel Validation Script
# Validates journey documentation with 5 Ollama models simultaneously

set -e

VALIDATION_DIR="/Users/dev1/github/medinovai-infrastructure/validation"
DOCS_DIR="/Users/dev1/github/medinovai-infrastructure/docs"
PROMPTS_DIR="$VALIDATION_DIR/prompts"
RESULTS_DIR="$VALIDATION_DIR/results"

echo "🚀 Starting 5-Model Parallel Validation"
echo "========================================"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Document files to validate
DOCS=(
    "$DOCS_DIR/COMPREHENSIVE_JOURNEY_VALIDATION_PLAN.md"
    "$DOCS_DIR/JOURNEY_VALIDATION_PLAN_SUMMARY.md"
    "$DOCS_DIR/JOURNEY_VALIDATION_SUMMARY.md"
    "$DOCS_DIR/JOURNEY_QUICK_REFERENCE.md"
    "$DOCS_DIR/JOURNEY_VALIDATION_INDEX.md"
)

# Models to use
declare -a MODEL_NAMES=(
    "qwen2.5:72b"
    "deepseek-coder:33b"
    "llama3.1:70b"
    "mixtral:8x22b"
    "codellama:70b"
)

declare -a MODEL_ROLES=(
    "Chief Architect"
    "Technical Reviewer"
    "Healthcare Expert"
    "Multi-Perspective Analyst"
    "Infrastructure Expert"
)

# Function to create full prompt with documentation
create_full_prompt() {
    local model_key=$1
    local prompt_file="$PROMPTS_DIR/${model_key//:/-}-prompt.txt"
    local full_prompt_file="$PROMPTS_DIR/${model_key//:/-}-full-prompt.txt"
    
    # Start with base prompt
    cat "$prompt_file" > "$full_prompt_file"
    
    # Add separator
    echo "" >> "$full_prompt_file"
    echo "===========================================" >> "$full_prompt_file"
    echo "DOCUMENTATION TO REVIEW:" >> "$full_prompt_file"
    echo "===========================================" >> "$full_prompt_file"
    echo "" >> "$full_prompt_file"
    
    # Add each document
    for i in "${!DOCS[@]}"; do
        local doc="${DOCS[$i]}"
        local doc_name=$(basename "$doc")
        
        echo "### DOCUMENT $((i+1)): $doc_name" >> "$full_prompt_file"
        echo "" >> "$full_prompt_file"
        
        if [ -f "$doc" ]; then
            cat "$doc" >> "$full_prompt_file"
        else
            echo "[Document not found: $doc]" >> "$full_prompt_file"
        fi
        
        echo "" >> "$full_prompt_file"
        echo "--- END OF DOCUMENT $((i+1)) ---" >> "$full_prompt_file"
        echo "" >> "$full_prompt_file"
    done
    
    echo "$full_prompt_file"
}

# Function to run validation with a single model
validate_with_model() {
    local model=$1
    local role=$2
    local result_file="$RESULTS_DIR/${model//:/-}-result.txt"
    local log_file="$RESULTS_DIR/${model//:/-}-log.txt"
    
    echo "[$(date '+%H:%M:%S')] 🤖 Starting $model ($role)..." | tee -a "$log_file"
    
    # Create full prompt
    local full_prompt=$(create_full_prompt "$model")
    
    # Run Ollama
    echo "[$(date '+%H:%M:%S')] 📝 Running validation..." | tee -a "$log_file"
    
    if ollama run "$model" < "$full_prompt" > "$result_file" 2>> "$log_file"; then
        echo "[$(date '+%H:%M:%S')] ✅ $model completed successfully" | tee -a "$log_file"
    else
        echo "[$(date '+%H:%M:%S')] ❌ $model failed" | tee -a "$log_file"
    fi
}

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

echo "📋 Documents to validate:"
for doc in "${DOCS[@]}"; do
    echo "   - $(basename "$doc")"
done
echo ""

echo "🤖 Models to use:"
for i in "${!MODEL_NAMES[@]}"; do
    echo "   - ${MODEL_NAMES[$i]} (${MODEL_ROLES[$i]})"
done
echo ""

echo "⏱️  Starting parallel execution at $(date '+%H:%M:%S')"
echo "   This will take approximately 1-2 hours..."
echo ""

# Start all models in parallel
pids=()
for i in "${!MODEL_NAMES[@]}"; do
    model="${MODEL_NAMES[$i]}"
    role="${MODEL_ROLES[$i]}"
    validate_with_model "$model" "$role" &
    pid=$!
    pids+=($pid)
    echo "✓ Started $model (PID: $pid)"
done

echo ""
echo "⏳ Waiting for all models to complete..."
echo "   You can monitor progress in: $RESULTS_DIR/*-log.txt"
echo ""

# Wait for all background jobs
for pid in "${pids[@]}"; do
    wait "$pid"
done

echo ""
echo "========================================"
echo "✅ All validations complete!"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "📊 Results available in:"
for model in "${MODEL_NAMES[@]}"; do
    result_file="$RESULTS_DIR/${model//:/-}-result.txt"
    if [ -f "$result_file" ]; then
        lines=$(wc -l < "$result_file")
        size=$(du -h "$result_file" | cut -f1)
        echo "   - ${model//:/-}-result.txt ($lines lines, $size)"
    fi
done
echo ""
echo "🔍 Next step: Run analysis script to aggregate scores"

