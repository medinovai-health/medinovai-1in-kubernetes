#!/bin/bash

# 5-Model Sequential Validation Script
# More reliable than parallel - runs one model at a time

set -e

VALIDATION_DIR="/Users/dev1/github/medinovai-infrastructure/validation"
DOCS_DIR="/Users/dev1/github/medinovai-infrastructure/docs"
PROMPTS_DIR="$VALIDATION_DIR/prompts"
RESULTS_DIR="$VALIDATION_DIR/results"

echo "🚀 Starting 5-Model Sequential Validation"
echo "=========================================="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Models to use (in order)
MODEL_1="qwen2.5:72b"
MODEL_2="deepseek-coder:33b"
MODEL_3="llama3.1:70b"
MODEL_4="mixtral:8x22b"
MODEL_5="codellama:70b"

ROLE_1="Chief Architect"
ROLE_2="Technical Reviewer"
ROLE_3="Healthcare Expert"
ROLE_4="Multi-Perspective Analyst"
ROLE_5="Infrastructure Expert"

# Function to validate with one model
validate_model() {
    local model=$1
    local role=$2
    local num=$3
    
    echo ""
    echo "═══════════════════════════════════════"
    echo "🤖 MODEL $num/5: $model"
    echo "Role: $role"
    echo "Started: $(date '+%H:%M:%S')"
    echo "═══════════════════════════════════════"
    
    local prompt_file="$PROMPTS_DIR/${model//:/-}-prompt.txt"
    local result_file="$RESULTS_DIR/${model//:/-}-result.txt"
    local log_file="$RESULTS_DIR/${model//:/-}-log.txt"
    
    # Create full prompt with documents
    local full_prompt="$PROMPTS_DIR/${model//:/-}-full-prompt.txt"
    
    cat "$prompt_file" > "$full_prompt"
    echo "" >> "$full_prompt"
    echo "===========================================" >> "$full_prompt"
    echo "DOCUMENTATION TO REVIEW:" >> "$full_prompt"
    echo "===========================================" >> "$full_prompt"
    echo "" >> "$full_prompt"
    
    # Add Document 1
    echo "### DOCUMENT 1: COMPREHENSIVE_JOURNEY_VALIDATION_PLAN.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    cat "$DOCS_DIR/COMPREHENSIVE_JOURNEY_VALIDATION_PLAN.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    echo "--- END OF DOCUMENT 1 ---" >> "$full_prompt"
    echo "" >> "$full_prompt"
    
    # Add Document 2
    echo "### DOCUMENT 2: JOURNEY_VALIDATION_PLAN_SUMMARY.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    cat "$DOCS_DIR/JOURNEY_VALIDATION_PLAN_SUMMARY.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    echo "--- END OF DOCUMENT 2 ---" >> "$full_prompt"
    echo "" >> "$full_prompt"
    
    # Add Document 3
    echo "### DOCUMENT 3: JOURNEY_VALIDATION_SUMMARY.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    cat "$DOCS_DIR/JOURNEY_VALIDATION_SUMMARY.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    echo "--- END OF DOCUMENT 3 ---" >> "$full_prompt"
    echo "" >> "$full_prompt"
    
    # Add Document 4
    echo "### DOCUMENT 4: JOURNEY_QUICK_REFERENCE.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    cat "$DOCS_DIR/JOURNEY_QUICK_REFERENCE.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    echo "--- END OF DOCUMENT 4 ---" >> "$full_prompt"
    echo "" >> "$full_prompt"
    
    # Add Document 5
    echo "### DOCUMENT 5: JOURNEY_VALIDATION_INDEX.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    cat "$DOCS_DIR/JOURNEY_VALIDATION_INDEX.md" >> "$full_prompt"
    echo "" >> "$full_prompt"
    echo "--- END OF DOCUMENT 5 ---" >> "$full_prompt"
    echo "" >> "$full_prompt"
    
    echo "📝 Running validation..."
    echo "   Prompt size: $(wc -l < "$full_prompt") lines"
    
    # Run ollama
    if ollama run "$model" < "$full_prompt" > "$result_file" 2> "$log_file"; then
        local lines=$(wc -l < "$result_file")
        local size=$(du -h "$result_file" | cut -f1)
        echo "✅ Completed: $lines lines, $size"
        echo "   Time: $(date '+%H:%M:%S')"
    else
        echo "❌ FAILED - check $log_file"
        return 1
    fi
}

# Create results directory
mkdir -p "$RESULTS_DIR"

echo "📋 Documents to validate:"
echo "   1. COMPREHENSIVE_JOURNEY_VALIDATION_PLAN.md"
echo "   2. JOURNEY_VALIDATION_PLAN_SUMMARY.md"
echo "   3. JOURNEY_VALIDATION_SUMMARY.md"
echo "   4. JOURNEY_QUICK_REFERENCE.md"
echo "   5. JOURNEY_VALIDATION_INDEX.md"
echo ""

echo "🤖 Models (sequential execution):"
echo "   1. $MODEL_1 ($ROLE_1)"
echo "   2. $MODEL_2 ($ROLE_2)"
echo "   3. $MODEL_3 ($ROLE_3)"
echo "   4. $MODEL_4 ($ROLE_4)"
echo "   5. $MODEL_5 ($ROLE_5)"
echo ""

START_TIME=$(date +%s)

# Run each model sequentially
validate_model "$MODEL_1" "$ROLE_1" "1"
validate_model "$MODEL_2" "$ROLE_2" "2"
validate_model "$MODEL_3" "$ROLE_3" "3"
validate_model "$MODEL_4" "$ROLE_4" "4"
validate_model "$MODEL_5" "$ROLE_5" "5"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "=========================================="
echo "🎉 ALL 5 MODELS COMPLETED!"
echo "=========================================="
echo "Total time: ${MINUTES}m ${SECONDS}s"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "📊 Results:"
for model in "$MODEL_1" "$MODEL_2" "$MODEL_3" "$MODEL_4" "$MODEL_5"; do
    result_file="$RESULTS_DIR/${model//:/-}-result.txt"
    if [ -f "$result_file" ]; then
        lines=$(wc -l < "$result_file")
        size=$(du -h "$result_file" | cut -f1)
        echo "   ✅ ${model}: $lines lines, $size"
    fi
done
echo ""
echo "🔍 Next step: python3 validation/analyze-results.py"

