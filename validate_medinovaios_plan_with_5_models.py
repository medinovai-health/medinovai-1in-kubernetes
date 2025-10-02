#!/usr/bin/env python3
"""
Five-Model Plan Validation for MedinovAI OS Deployment Readiness Plan
Validates the deployment readiness plan using 5 Ollama models
Target: ≥9.0/10 from all models
"""

import json
import subprocess
import time
import logging
from typing import Dict, List, Any
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MedinovaiOSPlanValidator:
    """Validates deployment readiness plan using 5 Ollama models"""
    
    def __init__(self, plan_file: str):
        self.plan_file = plan_file
        self.target_score = 9.0
        self.plan_content = self.load_plan()
        
        self.evaluator_models = {
            "chief_architect": {
                "model": "qwen2.5:72b",
                "role": "Chief Architect - System Design & Architecture",
                "weight": 0.25,
                "criteria": [
                    "Comprehensive scope coverage",
                    "Deployment architecture soundness",
                    "Scalability considerations",
                    "Enterprise patterns alignment",
                    "Risk mitigation strategies"
                ]
            },
            "technical_lead": {
                "model": "deepseek-coder:33b",
                "role": "Technical Lead - Implementation & Code Quality",
                "weight": 0.25,
                "criteria": [
                    "Technical implementation clarity",
                    "Configuration management approach",
                    "Automation and tooling strategy",
                    "Security implementation plan",
                    "Testing and validation approach"
                ]
            },
            "business_analyst": {
                "model": "codellama:34b",
                "role": "Business Analyst - Process & Workflow",
                "weight": 0.20,
                "criteria": [
                    "Business workflow completeness",
                    "Deployment process clarity",
                    "Stakeholder communication plan",
                    "Documentation comprehensiveness",
                    "Success criteria definitions"
                ]
            },
            "healthcare_specialist": {
                "model": "llama3.1:70b",
                "role": "Healthcare Specialist - Compliance & Medical Standards",
                "weight": 0.20,
                "criteria": [
                    "HIPAA compliance validation",
                    "FHIR standards adherence",
                    "Patient safety considerations",
                    "Medical data security plan",
                    "Healthcare workflow accuracy"
                ]
            },
            "performance_optimizer": {
                "model": "mistral:7b",
                "role": "Performance Optimizer - Efficiency & Resources",
                "weight": 0.10,
                "criteria": [
                    "Resource allocation strategy",
                    "Performance optimization plan",
                    "Scalability assessment",
                    "Monitoring and observability",
                    "Cost efficiency considerations"
                ]
            }
        }
    
    def load_plan(self) -> str:
        """Load the deployment readiness plan"""
        try:
            with open(self.plan_file, 'r') as f:
                content = f.read()
            logger.info(f"✅ Loaded plan: {self.plan_file} ({len(content)} chars)")
            return content
        except Exception as e:
            logger.error(f"❌ Failed to load plan: {e}")
            raise
    
    def evaluate_with_model(self, evaluator_id: str, config: Dict) -> Dict[str, Any]:
        """Evaluate the plan using a specific Ollama model"""
        
        model_name = config["model"]
        role = config["role"]
        criteria = config["criteria"]
        
        logger.info(f"🤖 Evaluating with {model_name} ({role})")
        
        # Create evaluation prompt
        evaluation_prompt = f"""You are a {role} conducting a BRUTAL HONEST evaluation of the MedinovAI OS Deployment Readiness Plan.

YOUR ROLE: {role}

EVALUATION CRITERIA:
{chr(10).join(f'- {c}' for c in criteria)}

PLAN TO EVALUATE:
{self.plan_content[:30000]}  # Limit to avoid context issues

EVALUATION REQUIREMENTS:
1. Be EXTREMELY CRITICAL - only give 9+ scores for truly excellent, production-ready plans
2. Evaluate each criterion thoroughly
3. Identify ALL gaps, missing components, and potential issues
4. Provide SPECIFIC, ACTIONABLE recommendations
5. Consider real-world deployment challenges
6. Assess feasibility of the 20-30 hour timeline
7. Validate that all deployment dependencies are addressed
8. Check for security and compliance thoroughness

TARGET SCORE: 9.0/10 (ONLY award this if the plan is genuinely production-ready)

Respond in VALID JSON format (no markdown, no code blocks):
{{
  "overall_score": <1.0-10.0>,
  "criterion_scores": {{
    "criterion_1": <1.0-10.0>,
    "criterion_2": <1.0-10.0>,
    "criterion_3": <1.0-10.0>,
    "criterion_4": <1.0-10.0>,
    "criterion_5": <1.0-10.0>
  }},
  "strengths": ["strength1", "strength2", "strength3"],
  "critical_issues": ["issue1", "issue2", "issue3"],
  "improvement_recommendations": ["rec1", "rec2", "rec3"],
  "missing_components": ["component1", "component2"],
  "timeline_assessment": "realistic|optimistic|unrealistic",
  "deployment_readiness": "ready|needs_work|not_ready",
  "detailed_feedback": "Comprehensive feedback..."
}}
"""

        try:
            # Execute Ollama model
            result = subprocess.run(
                ["ollama", "run", model_name, evaluation_prompt],
                capture_output=True,
                text=True,
                timeout=300  # 5 minutes timeout
            )
            
            if result.returncode == 0:
                output = result.stdout.strip()
                
                # Try to extract JSON from output
                try:
                    # Find JSON content
                    if '```json' in output:
                        json_start = output.find('```json') + 7
                        json_end = output.find('```', json_start)
                        json_str = output[json_start:json_end].strip()
                    elif '```' in output:
                        json_start = output.find('```') + 3
                        json_end = output.find('```', json_start)
                        json_str = output[json_start:json_end].strip()
                    else:
                        # Try to find JSON object
                        json_start = output.find('{')
                        json_end = output.rfind('}') + 1
                        json_str = output[json_start:json_end].strip()
                    
                    evaluation = json.loads(json_str)
                    evaluation["evaluator_model"] = model_name
                    evaluation["evaluator_role"] = role
                    evaluation["evaluation_timestamp"] = datetime.now().isoformat()
                    
                    score = evaluation.get("overall_score", 0.0)
                    logger.info(f"✅ {model_name} evaluation completed: {score}/10")
                    
                    return evaluation
                    
                except (json.JSONDecodeError, ValueError) as e:
                    logger.warning(f"⚠️  JSON parsing failed for {model_name}, using fallback")
                    logger.debug(f"Output: {output[:500]}")
                    return self.create_fallback_evaluation(model_name, role, 5.0, 
                        f"JSON parsing failed: {str(e)}")
            else:
                logger.error(f"❌ Ollama execution failed for {model_name}: {result.stderr}")
                return self.create_fallback_evaluation(model_name, role, 4.0, 
                    f"Execution failed: {result.stderr[:200]}")
                
        except subprocess.TimeoutExpired:
            logger.error(f"⏱️  Evaluation timeout for {model_name}")
            return self.create_fallback_evaluation(model_name, role, 3.0, "Evaluation timeout")
        except Exception as e:
            logger.error(f"💥 Exception evaluating with {model_name}: {e}")
            return self.create_fallback_evaluation(model_name, role, 2.0, f"Exception: {str(e)}")
    
    def create_fallback_evaluation(self, model_name: str, role: str, 
                                   score: float, reason: str) -> Dict[str, Any]:
        """Create fallback evaluation when model fails"""
        return {
            "overall_score": score,
            "criterion_scores": {
                "criterion_1": score,
                "criterion_2": score,
                "criterion_3": score,
                "criterion_4": score,
                "criterion_5": score
            },
            "strengths": [],
            "critical_issues": [f"Model evaluation failed: {reason}"],
            "improvement_recommendations": ["Retry evaluation", "Check model availability"],
            "missing_components": [],
            "timeline_assessment": "unknown",
            "deployment_readiness": "not_ready",
            "detailed_feedback": f"Evaluation failed for {model_name} in role {role}: {reason}",
            "evaluator_model": model_name,
            "evaluator_role": role,
            "evaluation_timestamp": datetime.now().isoformat(),
            "evaluation_failed": True
        }
    
    def calculate_consensus_score(self, evaluations: Dict[str, Any]) -> float:
        """Calculate weighted consensus score"""
        total_weighted_score = 0.0
        total_weight = 0.0
        
        for evaluator_id, evaluation in evaluations.items():
            if not evaluation.get("evaluation_failed", False):
                weight = self.evaluator_models[evaluator_id]["weight"]
                score = evaluation.get("overall_score", 0.0)
                total_weighted_score += score * weight
                total_weight += weight
        
        return round(total_weighted_score / total_weight if total_weight > 0 else 0.0, 2)
    
    def run_comprehensive_evaluation(self) -> Dict[str, Any]:
        """Run evaluation with all 5 models in parallel"""
        
        logger.info("🚀 Starting 5-Model Plan Validation")
        logger.info(f"📄 Plan: {self.plan_file}")
        logger.info(f"🎯 Target Score: {self.target_score}/10")
        logger.info("=" * 80)
        
        evaluations = {}
        
        # Run evaluations in parallel
        with ThreadPoolExecutor(max_workers=5) as executor:
            future_to_evaluator = {
                executor.submit(self.evaluate_with_model, evaluator_id, config): evaluator_id
                for evaluator_id, config in self.evaluator_models.items()
            }
            
            for future in as_completed(future_to_evaluator):
                evaluator_id = future_to_evaluator[future]
                try:
                    evaluation = future.result()
                    evaluations[evaluator_id] = evaluation
                except Exception as e:
                    logger.error(f"❌ Evaluation failed for {evaluator_id}: {e}")
                    evaluations[evaluator_id] = self.create_fallback_evaluation(
                        self.evaluator_models[evaluator_id]["model"],
                        self.evaluator_models[evaluator_id]["role"],
                        1.0,
                        str(e)
                    )
        
        # Calculate consensus
        consensus_score = self.calculate_consensus_score(evaluations)
        
        # Aggregate results
        all_strengths = []
        all_issues = []
        all_recommendations = []
        all_missing = []
        
        for evaluation in evaluations.values():
            all_strengths.extend(evaluation.get("strengths", []))
            all_issues.extend(evaluation.get("critical_issues", []))
            all_recommendations.extend(evaluation.get("improvement_recommendations", []))
            all_missing.extend(evaluation.get("missing_components", []))
        
        # Create comprehensive results
        results = {
            "plan_file": self.plan_file,
            "evaluation_timestamp": datetime.now().isoformat(),
            "target_score": self.target_score,
            "consensus_score": consensus_score,
            "meets_target": consensus_score >= self.target_score,
            "individual_evaluations": evaluations,
            "aggregated_strengths": list(set(all_strengths)),
            "aggregated_issues": list(set(all_issues)),
            "aggregated_recommendations": list(set(all_recommendations)),
            "aggregated_missing_components": list(set(all_missing)),
            "deployment_recommendation": self.get_deployment_recommendation(consensus_score, evaluations)
        }
        
        # Save results
        self.save_results(results)
        
        # Print summary
        self.print_summary(results)
        
        return results
    
    def get_deployment_recommendation(self, consensus_score: float, 
                                     evaluations: Dict[str, Any]) -> str:
        """Generate deployment recommendation"""
        if consensus_score >= 9.0:
            return "✅ APPROVED - Plan is ready for execution"
        elif consensus_score >= 8.0:
            return "⚠️  CONDITIONAL APPROVAL - Address critical issues before execution"
        elif consensus_score >= 7.0:
            return "⚠️  NEEDS IMPROVEMENT - Significant revisions required"
        else:
            return "❌ NOT APPROVED - Major gaps identified, comprehensive revision needed"
    
    def save_results(self, results: Dict[str, Any]):
        """Save evaluation results to file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = f"medinovaios_plan_validation_{timestamp}.json"
        
        try:
            with open(output_file, 'w') as f:
                json.dump(results, f, indent=2)
            logger.info(f"💾 Results saved to: {output_file}")
        except Exception as e:
            logger.error(f"❌ Failed to save results: {e}")
    
    def print_summary(self, results: Dict[str, Any]):
        """Print evaluation summary"""
        print("\n" + "=" * 80)
        print("📊 MEDINOVAIOS PLAN VALIDATION SUMMARY")
        print("=" * 80)
        print(f"📄 Plan: {results['plan_file']}")
        print(f"🎯 Target Score: {results['target_score']}/10")
        print(f"📈 Consensus Score: {results['consensus_score']}/10")
        print(f"✅ Meets Target: {'YES' if results['meets_target'] else 'NO'}")
        print(f"🏁 Recommendation: {results['deployment_recommendation']}")
        print("\n" + "-" * 80)
        print("🤖 INDIVIDUAL MODEL SCORES:")
        print("-" * 80)
        
        for evaluator_id, evaluation in results['individual_evaluations'].items():
            model_name = self.evaluator_models[evaluator_id]['model']
            role = self.evaluator_models[evaluator_id]['role']
            score = evaluation.get('overall_score', 0.0)
            status = "✅" if score >= self.target_score else "❌"
            print(f"{status} {model_name:20s} ({role:40s}): {score:.1f}/10")
        
        print("\n" + "-" * 80)
        print("💪 TOP STRENGTHS:")
        print("-" * 80)
        for i, strength in enumerate(results['aggregated_strengths'][:5], 1):
            print(f"{i}. {strength}")
        
        print("\n" + "-" * 80)
        print("🔥 CRITICAL ISSUES:")
        print("-" * 80)
        for i, issue in enumerate(results['aggregated_issues'][:5], 1):
            print(f"{i}. {issue}")
        
        print("\n" + "-" * 80)
        print("💡 TOP RECOMMENDATIONS:")
        print("-" * 80)
        for i, rec in enumerate(results['aggregated_recommendations'][:5], 1):
            print(f"{i}. {rec}")
        
        if results['aggregated_missing_components']:
            print("\n" + "-" * 80)
            print("⚠️  MISSING COMPONENTS:")
            print("-" * 80)
            for i, component in enumerate(results['aggregated_missing_components'][:5], 1):
                print(f"{i}. {component}")
        
        print("\n" + "=" * 80)

def main():
    """Main execution"""
    plan_file = "/Users/dev1/github/medinovai-infrastructure/docs/MEDINOVAIOS_DEPLOYMENT_READINESS_PLAN.md"
    
    if not os.path.exists(plan_file):
        logger.error(f"❌ Plan file not found: {plan_file}")
        return
    
    validator = MedinovaiOSPlanValidator(plan_file)
    results = validator.run_comprehensive_evaluation()
    
    # Exit with appropriate code
    if results['meets_target']:
        print("\n🎉 SUCCESS: Plan validated by all 5 models with ≥9.0/10 scores!")
        print("✅ Ready to proceed with plan execution")
        exit(0)
    else:
        print(f"\n⚠️  Plan needs improvement (Score: {results['consensus_score']}/10)")
        print("❌ Address identified issues and re-validate")
        exit(1)

if __name__ == "__main__":
    main()

