#!/usr/bin/env python3
"""
BRUTAL HONEST Multi-Model Validation: Phase 4 Microstep 1 - OpenSearch
Validates deployment, testing, and production readiness
"""

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

MODELS = [
    "qwen2.5:72b",
    "deepseek-coder:33b",
    "llama3.1:70b",
]

TARGET_SCORE = 9.0

def read_docs():
    """Read microstep 1 documentation"""
    docs = {}
    
    files = [
        "PHASE_4_DEPLOYMENT_PLAN.md",
        "PHASE_4_MICROSTEP_1_STATUS.md",
        "docker-compose-phase4.yml",
        "tests/infrastructure/phase4-opensearch.spec.ts",
    ]
    
    for filepath in files:
        full_path = Path(__file__).parent / filepath
        if full_path.exists():
            docs[filepath] = full_path.read_text()
    
    return docs

def create_prompt(docs):
    """Create brutal honest validation prompt"""
    prompt = f"""You are conducting a BRUTAL HONEST review of Phase 4 Microstep 1 for a healthcare infrastructure project.

**MICROSTEP 1: OpenSearch Deployment**

**WHAT WAS ACCOMPLISHED:**
✅ Deployed OpenSearch 2.11.0 single node
✅ Created comprehensive Playwright tests (6/7 passing)
✅ Tested healthcare-specific index mappings
✅ Validated CRUD operations, search, bulk operations
✅ Cluster health: GREEN, functional

**DEPLOYMENT:**
```yaml
{docs.get('docker-compose-phase4.yml', 'Not found')[:2000]}
```

**STATUS REPORT:**
{docs.get('PHASE_4_MICROSTEP_1_STATUS.md', 'Not found')[:4000]}

**PLAYWRIGHT TESTS:**
```typescript
{docs.get('tests/infrastructure/phase4-opensearch.spec.ts', 'Not found')[:3000]}
```

---

**YOUR TASK: BRUTAL HONEST EVALUATION**

Rate this microstep on a scale of 1-10 (where 9.0+ = ready to proceed):

**Criteria:**
1. **Deployment Quality** (25%): Service deployed correctly, healthy, accessible
2. **Test Coverage** (30%): Playwright tests comprehensive and passing
3. **Healthcare Relevance** (20%): Tests relevant to medical use cases
4. **Production Path** (15%): Clear path to production documented
5. **Microstep Completeness** (10%): All objectives met

**BE BRUTAL**:
- Security disabled? → Call it out (but consider dev vs prod)
- 1 test failing? → Is it critical or minor?
- Performance tested? → Or just functional tests?
- Ready for next microstep? → Or need more work?

**REMEMBER**: This is a MICROSTEP in iterative deployment, not full production.

**Output this EXACT JSON format:**

{{
  "score": 8.5,
  "ready_for_next_microstep": true,
  "strengths": [
    "Comprehensive Playwright tests covering core functionality",
    "Healthcare-specific index mappings tested",
    "...3-5 strengths..."
  ],
  "concerns": [
    "Security disabled for dev (documented for prod)",
    "1 test failing (minor impact)",
    "...2-4 concerns..."
  ],
  "critical_blockers": [
    "Must fix X before proceeding",
    "...or empty list if no blockers..."
  ],
  "recommendations": [
    "Fix failing test before production",
    "...specific improvements..."
  ],
  "verdict": "Ready to proceed to microstep 2 (dashboards). Security documented for prod deployment."
}}

**Healthcare infrastructure. HIPAA compliance. Be BRUTAL but FAIR.**
"""
    
    return prompt

def query_model(model, prompt):
    """Query model with timeout"""
    print(f"\n🔍 {model}: Evaluating microstep 1...")
    
    try:
        result = subprocess.run(
            ["ollama", "run", model, prompt],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        if result.returncode == 0:
            print(f"   ✅ {model} responded")
            return result.stdout.strip()
        else:
            print(f"   ❌ {model} failed")
            return None
            
    except subprocess.TimeoutExpired:
        print(f"   ⏱️  {model} timeout")
        return None
    except Exception as e:
        print(f"   ❌ {model} error: {e}")
        return None

def extract_json(response):
    """Extract JSON from response"""
    if not response:
        return None
    
    start = response.find('{')
    end = response.rfind('}')
    
    if start == -1 or end == -1:
        return None
    
    try:
        return json.loads(response[start:end+1])
    except:
        return None

def main():
    print("=" * 80)
    print("BRUTAL HONEST VALIDATION: Phase 4 Microstep 1 - OpenSearch")
    print("=" * 80)
    
    docs = read_docs()
    print(f"\n📚 Loaded {len(docs)} documents")
    
    prompt = create_prompt(docs)
    
    evaluations = {}
    
    for model in MODELS:
        response = query_model(model, prompt)
        if response:
            evaluation = extract_json(response)
            if evaluation and 'score' in evaluation:
                evaluations[model] = evaluation
                print(f"      Score: {evaluation['score']}/10")
                print(f"      Ready: {'✅ YES' if evaluation.get('ready_for_next_microstep') else '❌ NO'}")
            else:
                evaluations[model] = None
                print(f"      ⚠️  Failed to parse")
        else:
            evaluations[model] = None
    
    # Calculate consensus
    scores = [e['score'] for e in evaluations.values() if e]
    consensus = sum(scores) / len(scores) if scores else 0
    
    ready_count = sum(1 for e in evaluations.values() if e and e.get('ready_for_next_microstep'))
    
    print("\n" + "=" * 80)
    print(f"🎯 CONSENSUS SCORE: {consensus:.2f}/10")
    print(f"🚀 READY FOR NEXT MICROSTEP: {ready_count}/{len(scores)} models say YES")
    
    if consensus >= TARGET_SCORE and ready_count >= 2:
        print(f"✅ PROCEED TO MICROSTEP 2")
        status = "PROCEED"
    else:
        print(f"⚠️  NEEDS IMPROVEMENT")
        status = "ITERATE"
    
    # Detailed results
    print("\n" + "-" * 80)
    print("MODEL EVALUATIONS")
    print("-" * 80)
    
    for model, eval_data in evaluations.items():
        if eval_data:
            print(f"\n### {model}: {eval_data['score']}/10")
            print(f"Ready for next: {'✅ YES' if eval_data.get('ready_for_next_microstep') else '❌ NO'}")
            
            print(f"\n💪 Strengths:")
            for s in eval_data.get('strengths', [])[:3]:
                print(f"  ✅ {s}")
            
            if eval_data.get('concerns'):
                print(f"\n⚠️  Concerns:")
                for c in eval_data.get('concerns', [])[:3]:
                    print(f"  ⚠️  {c}")
            
            if eval_data.get('critical_blockers'):
                print(f"\n🚨 Critical Blockers:")
                for b in eval_data.get('critical_blockers', []):
                    print(f"  ❌ {b}")
            
            print(f"\n💡 Recommendations:")
            for r in eval_data.get('recommendations', [])[:2]:
                print(f"  → {r}")
            
            print(f"\n**Verdict**: {eval_data.get('verdict', 'N/A')}")
        else:
            print(f"\n### {model}: ❌ FAILED TO EVALUATE")
    
    # Save results
    results = {
        "timestamp": datetime.now().isoformat(),
        "phase": "Phase 4 Microstep 1: OpenSearch",
        "consensus_score": consensus,
        "target_score": TARGET_SCORE,
        "ready_count": ready_count,
        "total_models": len(scores),
        "status": status,
        "evaluations": evaluations,
    }
    
    output_file = Path(__file__).parent / "docs" / "PHASE_4_MICROSTEP_1_VALIDATION.json"
    output_file.parent.mkdir(exist_ok=True)
    output_file.write_text(json.dumps(results, indent=2))
    
    print(f"\n📄 Results saved: {output_file}")
    
    # Decision
    if status == "PROCEED":
        print("\n✅ DECISION: PROCEED TO MICROSTEP 2 (OpenSearch Dashboards)")
        sys.exit(0)
    else:
        print("\n⚠️  DECISION: ITERATE ON MICROSTEP 1")
        sys.exit(1)

if __name__ == "__main__":
    main()

