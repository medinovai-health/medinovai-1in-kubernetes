#!/bin/bash

# Progress Monitor for 5-Model Validation
# Shows real-time status of all running model validations

VALIDATION_DIR="/Users/dev1/github/medinovai-infrastructure/validation"
RESULTS_DIR="$VALIDATION_DIR/results"

echo "🔍 5-Model Validation Progress Monitor"
echo "======================================="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Check if validation is running
if pgrep -f "run-parallel-validation.sh" > /dev/null; then
    echo "✅ Validation is RUNNING"
else
    echo "⚠️  Validation script not detected (may have completed or failed)"
fi

echo ""
echo "📊 Model Status:"
echo ""

# Check individual model processes
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

for i in "${!MODEL_NAMES[@]}"; do
    model="${MODEL_NAMES[$i]}"
    role="${MODEL_ROLES[$i]}"
    model_safe="${model//:/-}"
    result_file="$RESULTS_DIR/${model_safe}-result.txt"
    log_file="$RESULTS_DIR/${model_safe}-log.txt"
    
    echo "🤖 $model ($role)"
    
    # Check if model is running
    if pgrep -f "ollama run $model" > /dev/null; then
        echo "   Status: ⏳ RUNNING"
        
        # Show last log entry
        if [ -f "$log_file" ]; then
            last_log=$(tail -n 1 "$log_file" 2>/dev/null)
            echo "   Last log: $last_log"
        fi
    else
        # Check if completed
        if [ -f "$result_file" ] && [ -s "$result_file" ]; then
            lines=$(wc -l < "$result_file" 2>/dev/null)
            size=$(du -h "$result_file" 2>/dev/null | cut -f1)
            echo "   Status: ✅ COMPLETED"
            echo "   Output: $lines lines, $size"
        else
            echo "   Status: ⏸️  NOT STARTED or FAILED"
        fi
    fi
    echo ""
done

echo "======================================="
echo "📁 Results Directory: $RESULTS_DIR"
echo ""

# Count completed validations
completed=0
for model in "${MODEL_NAMES[@]}"; do
    model_safe="${model//:/-}"
    result_file="$RESULTS_DIR/${model_safe}-result.txt"
    if [ -f "$result_file" ] && [ -s "$result_file" ]; then
        ((completed++))
    fi
done

echo "Progress: $completed / ${#MODEL_NAMES[@]} models completed"

if [ $completed -eq ${#MODEL_NAMES[@]} ]; then
    echo ""
    echo "🎉 All validations complete!"
    echo "Run: python3 validation/analyze-results.py"
fi

echo ""
echo "💡 Tips:"
echo "   - Watch logs: tail -f $RESULTS_DIR/*-log.txt"
echo "   - Check results: ls -lh $RESULTS_DIR/"
echo "   - Re-run this monitor: ./validation/monitor-progress.sh"

