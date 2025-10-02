#!/usr/bin/env python3
"""
Validate Phase 1: Foundation Review & Documentation with 3 Ollama Models

Models:
- qwen2.5:72b (Chief Architect) - Overall architecture review
- deepseek-coder:33b (Code Quality Expert) - Technical implementation review
- llama3.1:70b (Healthcare Specialist) - Healthcare compliance review

Target: 9.0/10+ from all 3 models
"""

import json
import subprocess
import time
from datetime import datetime
from pathlib import Path

# Configuration
MODELS = {
    "chief_architect": {
        "model": "qwen2.5:72b",
        "role": "Chief Architect - Overall architecture and system design evaluation",
        "weight": 0.35,
        "criteria": [
            "Audit methodology quality",
            "Findings accuracy and completeness",
            "Migration plan soundness",
            "Risk assessment quality",
            "Architecture alignment with best practices"
        ]
    },
    "technical_lead": {
        "model": "deepseek-coder:33b",
        "role": "Code Quality Expert - Technical implementation review",
        "weight": 0.35,
        "criteria": [
            "Technical accuracy of findings",
            "Migration plan feasibility",
            "Code quality standards",
            "Testing strategy completeness",
            "Implementation practicality"
        ]
    },
    "healthcare_specialist": {
        "model": "llama3.1:70b",
        "role": "Healthcare Specialist - Healthcare compliance and security review",
        "weight": 0.30,
        "criteria": [
            "HIPAA compliance implications",
            "Healthcare data security",
            "Patient data protection",
            "Regulatory compliance",
            "Healthcare-specific risks"
        ]
    }
}

def read_phase1_report():
    """Read the Phase 1 complete report"""
    report_path = Path("/Users/dev1/github/medinovai-infrastructure/docs/PHASE_1_COMPLETE_REPORT.md")
    if not report_path.exists():
        raise FileNotFoundError(f"Phase 1 report not found: {report_path}")
    return report_path.read_text()

def read_supporting_docs():
    """Read supporting documentation"""
    docs = {}
    base_path = Path("/Users/dev1/github/medinovai-infrastructure/docs")
    
    files = [
        "repo_infrastructure_findings.txt",
        "detailed_infrastructure_findings.md",
        "INFRASTRUCTURE_MIGRATION_PLAN.json",
        "DEFINITIVE_MEDINOVAI_TECH_STACK.md",
        "TECH_STACK_IMPLEMENTATION_PLAN.md"
    ]
    
    for file in files:
        file_path = base_path / file
        if file_path.exists():
            docs[file] = file_path.read_text()
    
    return docs

def query_ollama(model, prompt, timeout=300):
    """Query Ollama model with timeout"""
    print(f"  🤖 Querying {model}...")
    
    cmd = ["ollama", "run", model]
    
    try:
        result = subprocess.run(
            cmd,
            input=prompt.encode(),
            capture_output=True,
            timeout=timeout,
            check=True
        )
        return result.stdout.decode('utf-8', errors='ignore').strip()
    except subprocess.TimeoutExpired:
        print(f"  ⚠️ {model} query timed out after {timeout}s")
        return None
    except subprocess.CalledProcessError as e:
        print(f"  ❌ {model} query failed: {e}")
        return None
    except Exception as e:
        print(f"  ❌ Unexpected error with {model}: {e}")
        return None

def create_validation_prompt(phase1_report, model_info):
    """Create validation prompt for a specific model"""
    
    prompt = f"""You are a {model_info['role']}.

Your task is to review the Phase 1: Foundation Review & Documentation for the MedinovAI infrastructure centralization project.

## YOUR EVALUATION CRITERIA:
{chr(10).join(f"- {criterion}" for criterion in model_info['criteria'])}

## PHASE 1 REPORT TO REVIEW:

{phase1_report}

## YOUR TASK:

Please provide a comprehensive evaluation in the following JSON format:

{{
  "overall_score": <float 0-10>,
  "criterion_scores": {{
    "criterion_1": <float 0-10>,
    "criterion_2": <float 0-10>,
    "criterion_3": <float 0-10>,
    "criterion_4": <float 0-10>,
    "criterion_5": <float 0-10>
  }},
  "strengths": [
    "strength 1",
    "strength 2",
    "strength 3"
  ],
  "concerns": [
    "concern 1",
    "concern 2"
  ],
  "recommendations": [
    "recommendation 1",
    "recommendation 2"
  ],
  "critical_issues": [
    "critical issue 1 (if any)"
  ],
  "approval": "APPROVED|APPROVED_WITH_CHANGES|REJECTED",
  "summary": "Brief 2-3 sentence summary of your evaluation"
}}

IMPORTANT:
- Be brutally honest
- Focus on your area of expertise
- Give specific, actionable feedback
- Only approve if score >= 9.0/10
- Identify any missing elements or risks
- MUST return valid JSON only, no other text

Provide your evaluation:"""

    return prompt

def parse_model_response(response, model_name):
    """Parse model response and extract JSON evaluation"""
    if not response:
        return None
    
    # Try to extract JSON from response
    try:
        # Look for JSON block
        start = response.find('{')
        end = response.rfind('}') + 1
        
        if start >= 0 and end > start:
            json_str = response[start:end]
            evaluation = json.loads(json_str)
            return evaluation
    except json.JSONDecodeError as e:
        print(f"  ⚠️ Failed to parse JSON from {model_name}: {e}")
        print(f"  Response preview: {response[:200]}...")
        
        # Return a default structure if parsing fails
        return {
            "overall_score": 7.0,
            "criterion_scores": {},
            "strengths": ["Response parsing failed"],
            "concerns": ["Could not parse model response"],
            "recommendations": ["Retry validation"],
            "critical_issues": ["JSON parsing error"],
            "approval": "APPROVED_WITH_CHANGES",
            "summary": f"Model {model_name} response could not be parsed correctly."
        }
    
    return None

def validate_with_model(model_name, model_info, phase1_report):
    """Validate Phase 1 with a single model"""
    print(f"\n{'='*80}")
    print(f"🤖 MODEL: {model_info['model']}")
    print(f"📋 ROLE: {model_info['role']}")
    print(f"⚖️  WEIGHT: {model_info['weight']}")
    print(f"{'='*80}\n")
    
    prompt = create_validation_prompt(phase1_report, model_info)
    response = query_ollama(model_info['model'], prompt, timeout=600)
    
    if not response:
        print(f"  ❌ No response from {model_info['model']}")
        return None
    
    evaluation = parse_model_response(response, model_info['model'])
    
    if evaluation:
        print(f"\n  ✅ Evaluation received:")
        print(f"     Overall Score: {evaluation.get('overall_score', 'N/A')}/10")
        print(f"     Approval: {evaluation.get('approval', 'N/A')}")
        print(f"     Summary: {evaluation.get('summary', 'N/A')[:100]}...")
    
    return evaluation

def calculate_consensus(evaluations):
    """Calculate weighted consensus score"""
    total_weighted_score = 0.0
    total_weight = 0.0
    
    for model_name, eval_data in evaluations.items():
        if eval_data and "evaluation" in eval_data:
            weight = eval_data["weight"]
            score = eval_data["evaluation"].get("overall_score", 0.0)
            
            # Ensure score is float
            if isinstance(score, str):
                try:
                    score = float(score)
                except ValueError:
                    score = 0.0
            
            total_weighted_score += float(score) * float(weight)
            total_weight += float(weight)
    
    consensus_score = total_weighted_score / total_weight if total_weight > 0 else 0.0
    return consensus_score

def generate_report(evaluations, consensus_score):
    """Generate validation report"""
    report = {
        "metadata": {
            "timestamp": datetime.now().isoformat(),
            "phase": "Phase 1: Foundation Review & Documentation",
            "target_score": 9.0,
            "consensus_score": round(consensus_score, 2),
            "status": "PASSED" if consensus_score >= 9.0 else "NEEDS_IMPROVEMENT"
        },
        "model_evaluations": evaluations,
        "aggregated_feedback": {
            "all_strengths": [],
            "all_concerns": [],
            "all_recommendations": [],
            "critical_issues": []
        },
        "conclusion": {
            "approved": consensus_score >= 9.0,
            "message": ""
        }
    }
    
    # Aggregate feedback
    for model_name, eval_data in evaluations.items():
        if eval_data and "evaluation" in eval_data:
            eval = eval_data["evaluation"]
            report["aggregated_feedback"]["all_strengths"].extend(eval.get("strengths", []))
            report["aggregated_feedback"]["all_concerns"].extend(eval.get("concerns", []))
            report["aggregated_feedback"]["all_recommendations"].extend(eval.get("recommendations", []))
            report["aggregated_feedback"]["critical_issues"].extend(eval.get("critical_issues", []))
    
    # Conclusion
    if consensus_score >= 9.0:
        report["conclusion"]["message"] = f"✅ PHASE 1 APPROVED: Consensus score {consensus_score:.2f}/10 meets target of 9.0/10+"
    else:
        report["conclusion"]["message"] = f"⚠️ NEEDS IMPROVEMENT: Consensus score {consensus_score:.2f}/10 below target of 9.0/10"
    
    return report

def save_report(report):
    """Save validation report"""
    output_file = Path("/Users/dev1/github/medinovai-infrastructure/docs/PHASE_1_VALIDATION_REPORT.json")
    output_file.write_text(json.dumps(report, indent=2))
    print(f"\n✅ Report saved: {output_file}")
    return output_file

def print_summary(report):
    """Print validation summary"""
    print(f"\n{'='*80}")
    print("📊 PHASE 1 VALIDATION SUMMARY")
    print(f"{'='*80}\n")
    
    print(f"🎯 Target Score: {report['metadata']['target_score']}/10")
    print(f"📈 Consensus Score: {report['metadata']['consensus_score']}/10")
    print(f"📊 Status: {report['metadata']['status']}")
    print()
    
    print("🤖 Model Scores:")
    for model_name, eval_data in report['model_evaluations'].items():
        if eval_data and "evaluation" in eval_data:
            score = eval_data["evaluation"].get("overall_score", "N/A")
            approval = eval_data["evaluation"].get("approval", "N/A")
            print(f"   {eval_data['model']}: {score}/10 ({approval})")
    print()
    
    print(f"✅ Conclusion: {report['conclusion']['message']}")
    print()
    
    if report['aggregated_feedback']['critical_issues']:
        print("🔴 CRITICAL ISSUES:")
        for issue in report['aggregated_feedback']['critical_issues']:
            if issue:  # Skip empty issues
                print(f"   - {issue}")
        print()
    
    if report['aggregated_feedback']['all_concerns']:
        print("⚠️  TOP CONCERNS:")
        for concern in report['aggregated_feedback']['all_concerns'][:5]:
            if concern:  # Skip empty concerns
                print(f"   - {concern}")
        print()
    
    if report['aggregated_feedback']['all_recommendations']:
        print("💡 TOP RECOMMENDATIONS:")
        for rec in report['aggregated_feedback']['all_recommendations'][:5]:
            if rec:  # Skip empty recommendations
                print(f"   - {rec}")
        print()

def main():
    """Main validation workflow"""
    print("🚀 PHASE 1 VALIDATION WITH 3 OLLAMA MODELS")
    print(f"{'='*80}\n")
    
    # Read Phase 1 report
    print("📖 Reading Phase 1 report...")
    phase1_report = read_phase1_report()
    print(f"✅ Loaded {len(phase1_report)} characters\n")
    
    # Validate with each model
    evaluations = {}
    
    for model_name, model_info in MODELS.items():
        evaluation = validate_with_model(model_name, model_info, phase1_report)
        
        evaluations[model_name] = {
            "model": model_info["model"],
            "role": model_info["role"],
            "weight": model_info["weight"],
            "evaluation": evaluation
        }
        
        # Small delay between models
        time.sleep(2)
    
    # Calculate consensus
    print(f"\n{'='*80}")
    print("📊 CALCULATING CONSENSUS SCORE")
    print(f"{'='*80}\n")
    
    consensus_score = calculate_consensus(evaluations)
    print(f"✅ Weighted Consensus Score: {consensus_score:.2f}/10")
    
    # Generate report
    report = generate_report(evaluations, consensus_score)
    
    # Save report
    report_file = save_report(report)
    
    # Print summary
    print_summary(report)
    
    # Return success/failure
    if consensus_score >= 9.0:
        print(f"\n🎉 SUCCESS: Phase 1 validated with {consensus_score:.2f}/10!")
        print("✅ Ready to proceed to Phase 2: Data Layer Deployment")
        return 0
    else:
        print(f"\n⚠️  NEEDS IMPROVEMENT: Phase 1 scored {consensus_score:.2f}/10")
        print("📋 Review recommendations and address concerns before proceeding")
        return 1

if __name__ == "__main__":
    exit(main())

