#!/bin/bash

# Real-Time Heartbeat Monitor for 5-Model Validation
# Shows live progress with timestamps and status

VALIDATION_DIR="/Users/dev1/github/medinovai-infrastructure/validation"
RESULTS_DIR="$VALIDATION_DIR/results"
LOG_FILE="$VALIDATION_DIR/sequential-execution.log"

clear
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🤖 5-MODEL VALIDATION - REAL-TIME HEARTBEAT          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if validation is running
if pgrep -f "run-sequential-validation" > /dev/null || pgrep -f "ollama run" > /dev/null; then
    echo "Status: ✅ VALIDATION RUNNING"
else
    echo "Status: ⚠️  No validation detected"
fi

echo ""
echo "Current Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MODEL STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Models to check
declare -a MODELS=("qwen2.5-72b" "deepseek-coder-33b" "llama3.1-70b" "mixtral-8x22b" "codellama-70b")
declare -a ROLES=("Chief Architect" "Technical Reviewer" "Healthcare Expert" "Multi-Perspective" "Infrastructure Expert")

completed=0
for i in "${!MODELS[@]}"; do
    model="${MODELS[$i]}"
    role="${ROLES[$i]}"
    num=$((i+1))
    
    result_file="$RESULTS_DIR/${model}-result.txt"
    log_file="$RESULTS_DIR/${model}-log.txt"
    
    # Check if currently running
    if pgrep -f "ollama run ${model//-/:}" > /dev/null; then
        # Get elapsed time
        pid=$(pgrep -f "ollama run ${model//-/:}")
        elapsed=$(ps -p $pid -o etime= | tr -d ' ')
        
        echo "[$num/5] 🔄 $model"
        echo "      Role: $role"
        echo "      Status: ⏳ RUNNING (elapsed: $elapsed)"
        
        # Show last log line if available
        if [ -f "$log_file" ]; then
            last_log=$(tail -n 1 "$log_file" 2>/dev/null | head -c 80)
            if [ -n "$last_log" ]; then
                echo "      Activity: $last_log..."
            fi
        fi
        echo ""
        
    # Check if completed
    elif [ -f "$result_file" ] && [ -s "$result_file" ]; then
        lines=$(wc -l < "$result_file" 2>/dev/null)
        size=$(du -h "$result_file" 2>/dev/null | cut -f1)
        
        echo "[$num/5] ✅ $model"
        echo "      Role: $role"
        echo "      Status: COMPLETED"
        echo "      Output: $lines lines, $size"
        echo ""
        
        ((completed++))
        
    else
        echo "[$num/5] ⏸️  $model"
        echo "      Role: $role"
        echo "      Status: PENDING"
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROGRESS: $completed / 5 models completed"

# Calculate percentage
percent=$((completed * 100 / 5))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Progress bar
echo -n "Progress: ["
for ((i=0; i<completed; i++)); do echo -n "█"; done
for ((i=completed; i<5; i++)); do echo -n "░"; done
echo "] $percent%"
echo ""

# Show recent execution log
if [ -f "$LOG_FILE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "RECENT ACTIVITY (last 5 lines)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -n 5 "$LOG_FILE" 2>/dev/null || echo "(no activity yet)"
    echo ""
fi

# Check if all complete
if [ $completed -eq 5 ]; then
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  🎉 ALL VALIDATIONS COMPLETE!                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next step: python3 validation/analyze-results.py"
    echo ""
else
    echo "💡 Commands:"
    echo "   • Watch live: watch -n 5 './validation/heartbeat-monitor.sh'"
    echo "   • View logs: tail -f validation/sequential-execution.log"
    echo "   • Check status: ps aux | grep 'ollama run'"
fi

echo ""
echo "Last updated: $(date '+%H:%M:%S')"

