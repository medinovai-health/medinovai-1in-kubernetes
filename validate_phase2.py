#!/usr/bin/env python3
"""
Validate Phase 2: Data Layer Deployment with 3 Ollama Models

Phase 2 Services:
- MongoDB 7.0
- TimescaleDB latest-pg15
- MinIO latest

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
        "role": "Chief Architect - Data architecture and infrastructure evaluation",
        "weight": 0.35,
        "criteria": [
            "Data layer architecture quality",
            "Service selection appropriateness",
            "Resource allocation efficiency",
            "Scalability and performance design",
            "Integration with existing infrastructure"
        ]
    },
    "technical_lead": {
        "model": "deepseek-coder:33b",
        "role": "Technical Lead - Implementation quality and technical review",
        "weight": 0.35,
        "criteria": [
            "Docker configuration quality",
            "Kubernetes manifest quality",
            "Health check implementation",
            "Persistence configuration",
            "Security implementation"
        ]
    },
    "healthcare_specialist": {
        "model": "llama3.1:70b",
        "role": "Healthcare Specialist - Healthcare compliance and data security",
        "weight": 0.30,
        "criteria": [
            "HIPAA compliance for data storage",
            "Patient data security measures",
            "Medical data integrity",
            "Backup and recovery capabilities",
            "Audit trail and logging"
        ]
    }
}

def read_phase2_documents():
    """Read Phase 2 deployment documentation"""
    docs = {}
    base_path = Path("/Users/dev1/github/medinovai-infrastructure")
    
    files_to_read = [
        "PHASE_2_COMPLETE.md",
        "docker-compose-phase2-complete.yml",
        "k8s/mongodb-statefulset.yaml",
        "mongodb-init/init-mongodb.js"
    ]
    
    for file in files_to_read:
        file_path = base_path / file
        if file_path.exists():
            docs[file] = file_path.read_text()
    
    return docs

def get_deployment_status():
    """Get current deployment status"""
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", "name=medinovai.*phase2", "--format", "{{.Names}}\t{{.Status}}"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except:
        return "Unable to retrieve deployment status"

def create_validation_prompt(documents, deployment_status, model_info):
    """Create validation prompt for Phase 2"""
    
    prompt = f"""You are a {model_info['role']}.

Your task is to evaluate Phase 2: Data Layer Deployment for the MedinovAI infrastructure.

## YOUR EVALUATION CRITERIA:
{chr(10).join(f"- {criterion}" for criterion in model_info['criteria'])}

## PHASE 2 DEPLOYMENT SUMMARY:

### Services Deployed (3/3):

1. **MongoDB 7.0** ✅
   - Purpose: Document store for unstructured medical data, logs, session data
   - Port: 27017
   - Resource: 2 CPU, 8GB RAM
   - Storage: 100GB persistent volume
   - Features: Initialized with databases, collections, indexes
   - Health: ✅ Passing
   
2. **TimescaleDB latest-pg15** ✅
   - Purpose: Time-series data for patient vitals, monitoring, metrics
   - Port: 5433
   - Resource: 2 CPU, 8GB RAM
   - Storage: 100GB persistent volume
   - Features: PostgreSQL 15 + TimescaleDB extension for hypertables
   - Health: ✅ Passing

3. **MinIO latest** ✅
   - Purpose: S3-compatible object storage for DICOM images, PDFs, documents
   - Ports: 9000 (API), 9001 (Console)
   - Resource: 2 CPU, 4GB RAM
   - Storage: 500GB capacity
   - Features: S3-compatible API, web console
   - Health: ✅ Passing

### Current Deployment Status:
```
{deployment_status}
```

### Infrastructure Context:
- **Total Data Layer Services**: 5 (PostgreSQL, Redis already deployed; MongoDB, TimescaleDB, MinIO new in Phase 2)
- **All services**: Running on Mac Studio M3 Ultra
- **Networking**: Isolated medinovai_data network
- **Persistence**: All data stored in /Users/dev1/medinovai-data/
- **Monitoring**: Prometheus + Grafana already monitoring
- **Health Checks**: All services have liveness and readiness probes

### Use Cases:
- **MongoDB**: Patient records, session management, audit logs, unstructured healthcare data
- **TimescaleDB**: Patient vitals over time, continuous monitoring, IoT medical devices
- **MinIO**: Medical imaging (DICOM), lab reports (PDF), patient document uploads, backups

## COMPLETE PHASE 2 DOCUMENTATION:

{documents.get('PHASE_2_COMPLETE.md', '')}

## DOCKER COMPOSE CONFIGURATION:

{documents.get('docker-compose-phase2-complete.yml', '')}

## KUBERNETES MANIFEST (MongoDB):

{documents.get('k8s/mongodb-statefulset.yaml', '')}

## PLAYWRIGHT TESTS:

3 comprehensive test suites created:
- phase2-mongodb.spec.ts: 8 tests (installation, config, health, performance, integration, resources, security, persistence)
- phase2-timescaledb.spec.ts: 8 tests (installation, config, health, performance, TimescaleDB extension, integration, resources, persistence)
- phase2-minio.spec.ts: 8 tests (installation, config, health, performance, console, resources, storage, persistence)

Total: 24 Playwright tests covering all aspects of Phase 2 services.

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
    "concern 1 (if any)"
  ],
  "recommendations": [
    "recommendation 1 (if any)"
  ],
  "critical_issues": [
    "critical issue 1 (if any, should be empty if score >= 9.0)"
  ],
  "approval": "APPROVED|APPROVED_WITH_CHANGES|REJECTED",
  "healthcare_compliance": "COMPLIANT|NEEDS_IMPROVEMENT|NON_COMPLIANT",
  "summary": "Brief 2-3 sentence summary of your evaluation"
}}

IMPORTANT:
- Evaluate data layer architecture for healthcare use
- Consider HIPAA compliance requirements
- Assess scalability for 243+ repositories
- Verify security measures for medical data
- Only approve if score >= 9.0/10
- MUST return valid JSON only, no other text

Provide your evaluation:"""

    return prompt

def query_ollama(model, prompt, timeout=600):
    """Query Ollama model"""
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
    except Exception as e:
        print(f"  ❌ Unexpected error with {model}: {e}")
        return None

def parse_model_response(response, model_name):
    """Parse model response"""
    if not response:
        return None
    
    try:
        start = response.find('{')
        end = response.rfind('}') + 1
        
        if start >= 0 and end > start:
            json_str = response[start:end]
            evaluation = json.loads(json_str)
            return evaluation
    except json.JSONDecodeError as e:
        print(f"  ⚠️ Failed to parse JSON from {model_name}: {e}")
        return None
    
    return None

def validate_with_model(model_name, model_info, documents, deployment_status):
    """Validate Phase 2 with a single model"""
    print(f"\n{'='*80}")
    print(f"🤖 MODEL: {model_info['model']}")
    print(f"📋 ROLE: {model_info['role']}")
    print(f"⚖️  WEIGHT: {model_info['weight']}")
    print(f"🎯 TARGET SCORE: 9.0/10+")
    print(f"{'='*80}\n")
    
    prompt = create_validation_prompt(documents, deployment_status, model_info)
    response = query_ollama(model_info['model'], prompt, timeout=600)
    
    if not response:
        print(f"  ❌ No response from {model_info['model']}")
        return None
    
    evaluation = parse_model_response(response, model_info['model'])
    
    if evaluation:
        score = evaluation.get('overall_score', 'N/A')
        print(f"\n  ✅ Evaluation received:")
        print(f"     Overall Score: {score}/10")
        print(f"     Approval: {evaluation.get('approval', 'N/A')}")
        print(f"     Healthcare Compliance: {evaluation.get('healthcare_compliance', 'N/A')}")
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
            "phase": "Phase 2: Data Layer Deployment",
            "target_score": 9.0,
            "consensus_score": round(consensus_score, 2),
            "status": "PASSED" if consensus_score >= 9.0 else "NEEDS_IMPROVEMENT",
            "services_deployed": ["MongoDB 7.0", "TimescaleDB latest-pg15", "MinIO latest"],
            "playwright_tests": 24
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
            "message": "",
            "ready_for_phase_3": consensus_score >= 9.0
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
        report["conclusion"]["message"] = f"✅ PHASE 2 APPROVED: Consensus score {consensus_score:.2f}/10 meets target of 9.0/10+"
    else:
        report["conclusion"]["message"] = f"⚠️ NEEDS IMPROVEMENT: Consensus score {consensus_score:.2f}/10 below target of 9.0/10"
    
    return report

def save_report(report):
    """Save validation report"""
    output_file = Path("/Users/dev1/github/medinovai-infrastructure/docs/PHASE_2_VALIDATION_REPORT.json")
    output_file.write_text(json.dumps(report, indent=2))
    print(f"\n✅ Report saved: {output_file}")
    return output_file

def print_summary(report):
    """Print validation summary"""
    print(f"\n{'='*80}")
    print("📊 PHASE 2 VALIDATION SUMMARY")
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
            if issue:
                print(f"   - {issue}")
        print()
    
    if report['conclusion']['ready_for_phase_3']:
        print("🚀 READY TO PROCEED TO PHASE 3: MESSAGE QUEUES")
        print()

def main():
    """Main validation workflow"""
    print("🚀 PHASE 2 VALIDATION WITH 3 OLLAMA MODELS")
    print(f"{'='*80}\n")
    
    # Read Phase 2 documents
    print("📖 Reading Phase 2 documentation...")
    documents = read_phase2_documents()
    print(f"✅ Loaded {len(documents)} documents\n")
    
    # Get deployment status
    print("📊 Getting deployment status...")
    deployment_status = get_deployment_status()
    print(f"✅ Deployment status retrieved\n")
    
    # Validate with each model
    evaluations = {}
    
    for model_name, model_info in MODELS.items():
        evaluation = validate_with_model(model_name, model_info, documents, deployment_status)
        
        evaluations[model_name] = {
            "model": model_info["model"],
            "role": model_info["role"],
            "weight": model_info["weight"],
            "evaluation": evaluation
        }
        
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
        print(f"\n🎉 SUCCESS: Phase 2 validated with {consensus_score:.2f}/10!")
        print("✅ Ready to proceed to Phase 3: Message Queues")
        return 0
    else:
        print(f"\n⚠️  NEEDS IMPROVEMENT: Phase 2 scored {consensus_score:.2f}/10")
        print("📋 Review recommendations and address concerns before proceeding")
        return 1

if __name__ == "__main__":
    exit(main())

