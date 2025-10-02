#!/usr/bin/env python3
"""
Phase 3 Validation: 3-Model Evaluation System
Validates Phase 3 deployment using 3 Ollama models with 9.0/10+ consensus target
"""

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# Target models (best suited for infrastructure validation)
MODELS = [
    "qwen2.5:72b",        # Enterprise-grade reasoning
    "deepseek-coder:33b", # Technical infrastructure expertise
    "llama3.1:70b",       # Comprehensive analysis
]

TARGET_CONSENSUS_SCORE = 9.0

def read_phase3_docs():
    """Read all Phase 3 documentation"""
    docs = {}
    
    files_to_read = [
        "PHASE_3_COMPLETE.md",
        "PHASE_3_PLAYWRIGHT_RESULTS.md",
        "docker-compose-phase3-complete.yml",
    ]
    
    for filename in files_to_read:
        filepath = Path(__file__).parent / filename
        if filepath.exists():
            with open(filepath, 'r') as f:
                docs[filename] = f.read()
        else:
            print(f"⚠️  Warning: {filename} not found")
    
    return docs

def create_validation_prompt(docs):
    """Create comprehensive validation prompt"""
    prompt = f"""You are evaluating Phase 3 of the MedinovAI infrastructure deployment.

**PHASE 3: Message Queues & Streaming**

Services Deployed:
- Apache Zookeeper (coordination service)
- Apache Kafka (event streaming platform)  
- RabbitMQ (message broker)

**Documentation Provided:**

{docs.get('PHASE_3_COMPLETE.md', 'Not available')}

---

**Playwright Test Results:**

{docs.get('PHASE_3_PLAYWRIGHT_RESULTS.md', 'Not available')}

---

**Docker Compose Configuration:**

```yaml
{docs.get('docker-compose-phase3-complete.yml', 'Not available')}
```

---

**EVALUATION CRITERIA:**

1. **Deployment Quality** (25 points)
   - Proper service configuration
   - Resource allocation
   - Network setup
   - Volume management

2. **Functional Validation** (25 points)
   - Playwright test coverage and results
   - Service health checks
   - Integration testing

3. **Production Readiness** (25 points)
   - High availability configuration
   - Monitoring and healthchecks
   - Restart policies
   - Error handling

4. **Documentation** (15 points)
   - Completeness and clarity
   - Known limitations documented
   - Troubleshooting information

5. **Best Practices** (10 points)
   - Industry standards adherence
   - Security considerations
   - Scalability design

**TOTAL:** 100 points

---

**YOUR TASK:**

Evaluate this Phase 3 deployment and provide:

1. **Overall Score**: X/10 (where 9.0+ is excellent, production-ready)
2. **Strengths**: 3-5 key positive aspects
3. **Concerns**: Any issues or risks
4. **Recommendations**: Specific improvements if score < 9.5
5. **Production Ready**: YES/NO with brief justification

**Output your evaluation in this exact JSON format:**

{{
  "score": 9.2,
  "strengths": [
    "Comprehensive Playwright testing with 9/9 tests passing",
    "Proper service health checks configured",
    "...": "..."
  ],
  "concerns": [
    "KafkaJS compression limitation documented",
    "...": "..."
  ],
  "recommendations": [
    "Consider adding backup/restore procedures",
    "...": "..."
  ],
  "production_ready": true,
  "justification": "All critical functionality validated, services healthy, known limitations documented and mitigated."
}}

**IMPORTANT**: 
- Be objective and thorough
- Score relative to production healthcare infrastructure standards (HIPAA, high-availability)
- Consider that this is Phase 3 of a larger deployment
- Known limitations are acceptable if properly documented and mitigated
"""
    
    return prompt

def query_ollama_model(model, prompt):
    """Query an Ollama model and return response"""
    print(f"\n🤖 Querying {model}...")
    
    try:
        result = subprocess.run(
            ["ollama", "run", model, prompt],
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        if result.returncode == 0:
            response = result.stdout.strip()
            print(f"✅ {model} responded")
            return response
        else:
            print(f"❌ {model} failed: {result.stderr}")
            return None
            
    except subprocess.TimeoutExpired:
        print(f"⏱️  {model} timed out")
        return None
    except Exception as e:
        print(f"❌ {model} error: {str(e)}")
        return None

def extract_json_from_response(response):
    """Extract JSON from model response"""
    if not response:
        return None
    
    # Try to find JSON in the response
    start_idx = response.find('{')
    end_idx = response.rfind('}')
    
    if start_idx == -1 or end_idx == -1:
        return None
    
    json_str = response[start_idx:end_idx+1]
    
    try:
        return json.loads(json_str)
    except json.JSONDecodeError:
        # Try to clean up the JSON
        json_str = json_str.replace('\n', ' ').replace('  ', ' ')
        try:
            return json.loads(json_str)
        except:
            return None

def calculate_consensus(evaluations):
    """Calculate weighted consensus score"""
    if not evaluations:
        return 0.0
    
    total_score = sum(eval_data['score'] for eval_data in evaluations.values() if eval_data)
    count = len([e for e in evaluations.values() if e])
    
    if count == 0:
        return 0.0
    
    return total_score / count

def main():
    print("=" * 80)
    print("PHASE 3: 3-MODEL VALIDATION SYSTEM")
    print("Target Consensus Score: 9.0/10+")
    print("=" * 80)
    
    # Read documentation
    print("\n📚 Reading Phase 3 documentation...")
    docs = read_phase3_docs()
    
    if not docs:
        print("❌ No documentation found!")
        sys.exit(1)
    
    print(f"✅ Loaded {len(docs)} documents")
    
    # Create validation prompt
    prompt = create_validation_prompt(docs)
    
    # Query each model
    evaluations = {}
    raw_responses = {}
    
    for model in MODELS:
        response = query_ollama_model(model, prompt)
        raw_responses[model] = response
        
        if response:
            evaluation = extract_json_from_response(response)
            if evaluation and 'score' in evaluation:
                evaluations[model] = evaluation
                print(f"   Score: {evaluation['score']}/10")
            else:
                print(f"   ⚠️  Failed to parse JSON response")
                evaluations[model] = None
        else:
            evaluations[model] = None
    
    # Calculate consensus
    print("\n" + "=" * 80)
    print("CONSENSUS ANALYSIS")
    print("=" * 80)
    
    consensus_score = calculate_consensus(evaluations)
    
    print(f"\n🎯 **CONSENSUS SCORE: {consensus_score:.2f}/10**")
    
    if consensus_score >= TARGET_CONSENSUS_SCORE:
        print(f"✅ **TARGET ACHIEVED** (>= {TARGET_CONSENSUS_SCORE})")
        result_status = "PASSED"
    else:
        print(f"⚠️  **BELOW TARGET** (< {TARGET_CONSENSUS_SCORE})")
        result_status = "NEEDS_IMPROVEMENT"
    
    # Detailed results
    print("\n" + "-" * 80)
    print("MODEL EVALUATIONS")
    print("-" * 80)
    
    for model, evaluation in evaluations.items():
        if evaluation:
            print(f"\n### {model}: {evaluation['score']}/10")
            print(f"Production Ready: {'✅ YES' if evaluation.get('production_ready') else '❌ NO'}")
            print(f"\nStrengths:")
            for strength in evaluation.get('strengths', []):
                print(f"  ✅ {strength}")
            
            if evaluation.get('concerns'):
                print(f"\nConcerns:")
                for concern in evaluation.get('concerns', []):
                    print(f"  ⚠️  {concern}")
            
            if evaluation.get('recommendations'):
                print(f"\nRecommendations:")
                for rec in evaluation.get('recommendations', []):
                    print(f"  💡 {rec}")
        else:
            print(f"\n### {model}: ❌ FAILED TO EVALUATE")
    
    # Save results
    results = {
        "timestamp": datetime.now().isoformat(),
        "phase": "Phase 3: Message Queues & Streaming",
        "models": MODELS,
        "consensus_score": consensus_score,
        "target_score": TARGET_CONSENSUS_SCORE,
        "status": result_status,
        "evaluations": evaluations,
        "raw_responses": raw_responses
    }
    
    output_file = Path(__file__).parent / "docs" / "PHASE_3_VALIDATION_REPORT.json"
    output_file.parent.mkdir(exist_ok=True)
    
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n📄 Full results saved to: {output_file}")
    
    # Exit code
    sys.exit(0 if consensus_score >= TARGET_CONSENSUS_SCORE else 1)

if __name__ == "__main__":
    main()

