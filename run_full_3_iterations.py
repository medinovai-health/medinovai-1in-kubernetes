#!/usr/bin/env python3
import subprocess
import time
import json
from datetime import datetime

results_summary = []

for i in range(1, 4):
    print(f"\n{'='*80}")
    print(f"🔄 RUNNING ITERATION {i}/3")
    print(f"{'='*80}\n")
    
    result = subprocess.run(
        ["python3", "validate_existing_deployment.py"],
        capture_output=True,
        text=True,
        timeout=120
    )
    
    # Extract score from output
    for line in result.stdout.split('\n'):
        if 'Consensus:' in line:
            try:
                score = float(line.split(':')[1].split('/')[0].strip())
                results_summary.append({
                    "iteration": i,
                    "score": score,
                    "timestamp": datetime.now().isoformat()
                })
                print(f"✅ Iteration {i} Score: {score}/10")
            except:
                pass
    
    if i < 3:
        print(f"\n⏳ Waiting 20 seconds before iteration {i+1}...\n")
        time.sleep(20)

# Final Summary
print(f"\n{'='*80}")
print("🏁 FINAL 3-ITERATION SUMMARY")
print(f"{'='*80}")
for result in results_summary:
    status = "✅" if result['score'] >= 9.0 else "⚠️"
    print(f"Iteration {result['iteration']}: {status} {result['score']}/10")

avg_score = sum(r['score'] for r in results_summary) / len(results_summary) if results_summary else 0
print(f"\n📊 Average Score: {avg_score:.2f}/10")
print(f"🎯 Target: 9.0/10")
print(f"✅ Success: {avg_score >= 9.0}")

with open(f"three_iterations_summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json", 'w') as f:
    json.dump({"iterations": results_summary, "average": avg_score}, f, indent=2)
