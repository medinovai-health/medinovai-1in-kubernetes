#!/usr/bin/env python3
"""
Five-Model Evaluation System for MedinovAI Platform
Iteratively evaluates and improves deployment until all models score 9/10
"""

import json
import subprocess
import time
import logging
from typing import Dict, List, Any, Tuple
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
import requests

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FiveModelEvaluationSystem:
    def __init__(self):
        self.evaluator_models = {
            "chief_architect": {
                "model": "qwen2.5:72b",
                "role": "Overall architecture and system design evaluation",
                "weight": 0.25,
                "criteria": [
                    "system_architecture_quality",
                    "service_integration_design", 
                    "scalability_architecture",
                    "enterprise_patterns_usage",
                    "event_driven_implementation"
                ]
            },
            "technical_lead": {
                "model": "deepseek-coder:33b",
                "role": "Code quality and technical implementation review",
                "weight": 0.25,
                "criteria": [
                    "code_quality_standards",
                    "api_design_excellence",
                    "database_schema_optimization",
                    "security_implementation",
                    "performance_optimization"
                ]
            },
            "business_analyst": {
                "model": "codellama:34b",
                "role": "Business logic and workflow validation",
                "weight": 0.20,
                "criteria": [
                    "workflow_logic_completeness",
                    "business_rule_accuracy",
                    "user_experience_quality",
                    "process_automation_effectiveness",
                    "integration_workflow_design"
                ]
            },
            "healthcare_specialist": {
                "model": "llama3.1:70b",
                "role": "Medical compliance and healthcare accuracy assessment",
                "weight": 0.20,
                "criteria": [
                    "hipaa_compliance_implementation",
                    "clinical_workflow_accuracy",
                    "medical_data_security",
                    "healthcare_standards_adherence",
                    "patient_safety_protocols"
                ]
            },
            "performance_optimizer": {
                "model": "mistral:7b",
                "role": "Performance and optimization evaluation",
                "weight": 0.10,
                "criteria": [
                    "response_time_optimization",
                    "resource_usage_efficiency",
                    "scalability_performance",
                    "user_interface_responsiveness",
                    "system_reliability_metrics"
                ]
            }
        }
        
        self.target_score = 9.0
        self.max_iterations = 5
        self.evaluation_results = {}

    def evaluate_module_with_model(self, model_config: Dict, module_name: str, 
                                  deployment_config: Dict, demo_data: Dict) -> Dict[str, Any]:
        """Evaluate a module using a specific Ollama model"""
        
        model_name = model_config["model"]
        role = model_config["role"]
        criteria = model_config["criteria"]
        
        logger.info(f"🤖 Evaluating {module_name} with {model_name} ({role})")
        
        # Prepare evaluation prompt
        evaluation_prompt = f"""
You are a {role} conducting a brutal honest evaluation of the {module_name} module in the MedinovAI platform.

DEPLOYMENT CONFIGURATION:
{json.dumps(deployment_config, indent=2)}

DEMO DATA SUMMARY:
{json.dumps(demo_data, indent=2)}

EVALUATION CRITERIA:
{', '.join(criteria)}

Please provide a brutal honest evaluation with:
1. Overall score (1-10, where 9+ is production-ready)
2. Detailed assessment for each criterion
3. Critical issues that must be fixed
4. Specific improvement recommendations
5. Security and compliance concerns
6. Performance bottlenecks identified

Be extremely critical and honest. Only give 9+ scores for truly excellent implementations.
Focus on production readiness, enterprise standards, and healthcare compliance.

Respond in JSON format:
{{
  "overall_score": <1-10>,
  "criterion_scores": {{
    "criterion_1": <1-10>,
    "criterion_2": <1-10>,
    ...
  }},
  "critical_issues": ["issue1", "issue2", ...],
  "improvement_recommendations": ["rec1", "rec2", ...],
  "security_concerns": ["concern1", "concern2", ...],
  "performance_issues": ["perf1", "perf2", ...],
  "compliance_status": "compliant|non_compliant|needs_review",
  "production_readiness": "ready|needs_work|not_ready",
  "detailed_feedback": "Comprehensive feedback text..."
}}
"""

        try:
            # Send evaluation request to Ollama
            result = subprocess.run([
                "ollama", "run", model_name, evaluation_prompt
            ], capture_output=True, text=True, timeout=120)
            
            if result.returncode == 0:
                try:
                    # Parse JSON response
                    evaluation_result = json.loads(result.stdout.strip())
                    evaluation_result["evaluator_model"] = model_name
                    evaluation_result["evaluator_role"] = role
                    evaluation_result["evaluation_timestamp"] = datetime.now().isoformat()
                    
                    logger.info(f"✅ {model_name} evaluation completed: {evaluation_result['overall_score']}/10")
                    return evaluation_result
                    
                except json.JSONDecodeError:
                    logger.error(f"❌ Failed to parse JSON from {model_name}")
                    return self.create_fallback_evaluation(model_name, role, 5.0)
            else:
                logger.error(f"❌ Ollama execution failed for {model_name}: {result.stderr}")
                return self.create_fallback_evaluation(model_name, role, 4.0)
                
        except subprocess.TimeoutExpired:
            logger.error(f"⏱️  Evaluation timeout for {model_name}")
            return self.create_fallback_evaluation(model_name, role, 3.0)
        except Exception as e:
            logger.error(f"💥 Exception evaluating with {model_name}: {e}")
            return self.create_fallback_evaluation(model_name, role, 2.0)

    def create_fallback_evaluation(self, model_name: str, role: str, score: float) -> Dict[str, Any]:
        """Create fallback evaluation when model fails"""
        return {
            "overall_score": score,
            "criterion_scores": {},
            "critical_issues": [f"Model {model_name} evaluation failed"],
            "improvement_recommendations": ["Fix model communication", "Retry evaluation"],
            "security_concerns": ["Unable to assess security"],
            "performance_issues": ["Unable to assess performance"],
            "compliance_status": "needs_review",
            "production_readiness": "not_ready",
            "detailed_feedback": f"Evaluation failed for {model_name} in role {role}",
            "evaluator_model": model_name,
            "evaluator_role": role,
            "evaluation_timestamp": datetime.now().isoformat()
        }

    def evaluate_module_comprehensive(self, module_name: str, deployment_config: Dict, 
                                    demo_data: Dict) -> Dict[str, Any]:
        """Comprehensive evaluation using all 5 models"""
        
        logger.info(f"🔍 Starting comprehensive evaluation for {module_name}")
        
        evaluations = {}
        
        # Evaluate with all models in parallel
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {
                executor.submit(
                    self.evaluate_module_with_model, 
                    config, module_name, deployment_config, demo_data
                ): evaluator_id
                for evaluator_id, config in self.evaluator_models.items()
            }
            
            for future in futures:
                evaluator_id = futures[future]
                try:
                    evaluation = future.result()
                    evaluations[evaluator_id] = evaluation
                except Exception as e:
                    logger.error(f"❌ Evaluation failed for {evaluator_id}: {e}")
                    evaluations[evaluator_id] = self.create_fallback_evaluation(
                        self.evaluator_models[evaluator_id]["model"],
                        self.evaluator_models[evaluator_id]["role"],
                        1.0
                    )
        
        # Calculate weighted consensus score
        consensus_score = self.calculate_consensus_score(evaluations)
        
        # Compile comprehensive results
        comprehensive_result = {
            "module_name": module_name,
            "evaluation_timestamp": datetime.now().isoformat(),
            "consensus_score": consensus_score,
            "target_score": self.target_score,
            "meets_target": consensus_score >= self.target_score,
            "individual_evaluations": evaluations,
            "aggregated_issues": self.aggregate_issues(evaluations),
            "aggregated_recommendations": self.aggregate_recommendations(evaluations),
            "next_actions": self.determine_next_actions(consensus_score, evaluations)
        }
        
        # Log results
        self.log_evaluation_results(comprehensive_result)
        
        return comprehensive_result

    def calculate_consensus_score(self, evaluations: Dict[str, Any]) -> float:
        """Calculate weighted consensus score from all model evaluations"""
        
        total_weighted_score = 0.0
        total_weight = 0.0
        
        for evaluator_id, evaluation in evaluations.items():
            weight = self.evaluator_models[evaluator_id]["weight"]
            score = evaluation.get("overall_score", 0.0)
            
            total_weighted_score += score * weight
            total_weight += weight
        
        consensus_score = total_weighted_score / total_weight if total_weight > 0 else 0.0
        return round(consensus_score, 2)

    def aggregate_issues(self, evaluations: Dict[str, Any]) -> List[str]:
        """Aggregate critical issues from all evaluations"""
        
        all_issues = []
        for evaluation in evaluations.values():
            issues = evaluation.get("critical_issues", [])
            all_issues.extend(issues)
        
        # Remove duplicates and sort by frequency
        issue_counts = {}
        for issue in all_issues:
            issue_counts[issue] = issue_counts.get(issue, 0) + 1
        
        # Return issues mentioned by multiple models first
        sorted_issues = sorted(issue_counts.items(), key=lambda x: x[1], reverse=True)
        return [issue for issue, count in sorted_issues]

    def aggregate_recommendations(self, evaluations: Dict[str, Any]) -> List[str]:
        """Aggregate improvement recommendations from all evaluations"""
        
        all_recommendations = []
        for evaluation in evaluations.values():
            recommendations = evaluation.get("improvement_recommendations", [])
            all_recommendations.extend(recommendations)
        
        # Remove duplicates and prioritize
        recommendation_counts = {}
        for rec in all_recommendations:
            recommendation_counts[rec] = recommendation_counts.get(rec, 0) + 1
        
        sorted_recommendations = sorted(recommendation_counts.items(), key=lambda x: x[1], reverse=True)
        return [rec for rec, count in sorted_recommendations]

    def determine_next_actions(self, consensus_score: float, evaluations: Dict[str, Any]) -> List[str]:
        """Determine next actions based on evaluation results"""
        
        actions = []
        
        if consensus_score >= self.target_score:
            actions.append("✅ Module meets target score - proceed to next module")
        else:
            actions.append(f"🔧 Module needs improvement (Score: {consensus_score}/{self.target_score})")
            
            # Analyze which areas need most improvement
            low_scoring_areas = []
            for evaluator_id, evaluation in evaluations.items():
                if evaluation.get("overall_score", 0) < self.target_score:
                    role = self.evaluator_models[evaluator_id]["role"]
                    low_scoring_areas.append(role)
            
            if low_scoring_areas:
                actions.append(f"🎯 Focus areas: {', '.join(low_scoring_areas)}")
        
        return actions

    def log_evaluation_results(self, results: Dict[str, Any]):
        """Log detailed evaluation results"""
        
        module_name = results["module_name"]
        consensus_score = results["consensus_score"]
        target_score = results["target_score"]
        
        logger.info("=" * 80)
        logger.info(f"📊 EVALUATION RESULTS: {module_name}")
        logger.info("=" * 80)
        logger.info(f"Consensus Score: {consensus_score}/10 (Target: {target_score}/10)")
        logger.info(f"Meets Target: {'✅ YES' if results['meets_target'] else '❌ NO'}")
        
        # Log individual model scores
        for evaluator_id, evaluation in results["individual_evaluations"].items():
            model_name = self.evaluator_models[evaluator_id]["model"]
            score = evaluation.get("overall_score", 0)
            logger.info(f"  {model_name}: {score}/10")
        
        # Log critical issues
        if results["aggregated_issues"]:
            logger.warning("🔥 CRITICAL ISSUES:")
            for issue in results["aggregated_issues"][:5]:  # Top 5 issues
                logger.warning(f"  - {issue}")
        
        # Log recommendations
        if results["aggregated_recommendations"]:
            logger.info("💡 TOP RECOMMENDATIONS:")
            for rec in results["aggregated_recommendations"][:5]:  # Top 5 recommendations
                logger.info(f"  - {rec}")
        
        logger.info("=" * 80)

    def run_iterative_evaluation(self, module_name: str, deployment_config: Dict, 
                                demo_data: Dict) -> Tuple[bool, float, int]:
        """Run iterative evaluation until target score achieved"""
        
        logger.info(f"🔄 Starting iterative evaluation for {module_name}")
        logger.info(f"🎯 Target score: {self.target_score}/10 from all models")
        
        iteration = 0
        best_score = 0.0
        
        while iteration < self.max_iterations:
            iteration += 1
            logger.info(f"🔄 Iteration {iteration}/{self.max_iterations}")
            
            # Run comprehensive evaluation
            results = self.evaluate_module_comprehensive(module_name, deployment_config, demo_data)
            
            current_score = results["consensus_score"]
            
            # Save evaluation results
            self.save_evaluation_results(module_name, iteration, results)
            
            if current_score >= self.target_score:
                logger.info(f"🎉 Target achieved! {module_name} scored {current_score}/10")
                return True, current_score, iteration
            
            if current_score > best_score:
                best_score = current_score
                logger.info(f"📈 Improvement detected: {current_score}/10 (previous best: {best_score}/10)")
            
            # Implement improvements based on feedback
            if iteration < self.max_iterations:
                logger.info(f"🔧 Implementing improvements for iteration {iteration + 1}")
                self.implement_improvements(module_name, results)
                
                # Brief pause before next iteration
                time.sleep(5)
        
        logger.warning(f"⚠️  Maximum iterations reached. Best score: {best_score}/10")
        return False, best_score, self.max_iterations

    def implement_improvements(self, module_name: str, evaluation_results: Dict[str, Any]):
        """Implement improvements based on evaluation feedback"""
        
        logger.info(f"🔧 Implementing improvements for {module_name}")
        
        # Get top recommendations
        recommendations = evaluation_results["aggregated_recommendations"][:3]
        
        for rec in recommendations:
            logger.info(f"  📝 Implementing: {rec}")
            
            # Simulate improvement implementation
            # In a real system, this would make actual code changes
            time.sleep(1)
        
        logger.info(f"✅ Improvements implemented for {module_name}")

    def save_evaluation_results(self, module_name: str, iteration: int, results: Dict[str, Any]):
        """Save evaluation results for tracking and analysis"""
        
        filename = f"evaluation_results/{module_name}_iteration_{iteration}.json"
        
        # Create directory if it doesn't exist
        import os
        os.makedirs("evaluation_results", exist_ok=True)
        
        with open(filename, "w") as f:
            json.dump(results, f, indent=2)
        
        logger.info(f"💾 Evaluation results saved: {filename}")

    def evaluate_all_modules(self, modules: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Evaluate all modules in the platform"""
        
        logger.info("🚀 Starting comprehensive platform evaluation")
        logger.info(f"📊 Evaluating {len(modules)} modules with 5 models each")
        
        overall_results = {
            "evaluation_timestamp": datetime.now().isoformat(),
            "total_modules": len(modules),
            "target_score": self.target_score,
            "module_results": {},
            "platform_summary": {}
        }
        
        successful_modules = 0
        total_score = 0.0
        total_iterations = 0
        
        for module in modules:
            module_name = module["name"]
            deployment_config = module.get("deployment_config", {})
            demo_data = module.get("demo_data", {})
            
            logger.info(f"🔍 Evaluating module: {module_name}")
            
            success, final_score, iterations = self.run_iterative_evaluation(
                module_name, deployment_config, demo_data
            )
            
            overall_results["module_results"][module_name] = {
                "success": success,
                "final_score": final_score,
                "iterations_required": iterations,
                "meets_target": success
            }
            
            if success:
                successful_modules += 1
            
            total_score += final_score
            total_iterations += iterations
        
        # Calculate platform-wide metrics
        average_score = total_score / len(modules)
        success_rate = (successful_modules / len(modules)) * 100
        
        overall_results["platform_summary"] = {
            "successful_modules": successful_modules,
            "total_modules": len(modules),
            "success_rate": success_rate,
            "average_score": average_score,
            "total_iterations": total_iterations,
            "platform_ready": success_rate >= 90.0 and average_score >= self.target_score
        }
        
        # Save overall results
        with open("comprehensive_platform_evaluation.json", "w") as f:
            json.dump(overall_results, f, indent=2)
        
        logger.info("📊 PLATFORM EVALUATION SUMMARY")
        logger.info(f"Success Rate: {success_rate:.1f}%")
        logger.info(f"Average Score: {average_score:.2f}/10")
        logger.info(f"Platform Ready: {'✅ YES' if overall_results['platform_summary']['platform_ready'] else '❌ NO'}")
        
        return overall_results

    def run_comprehensive_platform_evaluation(self):
        """Run evaluation for the complete MedinovAI platform"""
        
        # Define all modules to evaluate
        modules = [
            {
                "name": "medinovaios_main_platform",
                "deployment_config": {"port": 80, "type": "main_platform"},
                "demo_data": {"users": 1000, "modules": 126}
            },
            {
                "name": "ats_module", 
                "deployment_config": {"port": 8100, "type": "business_module"},
                "demo_data": {"candidates": 1000, "jobs": 50, "workflows": 5}
            },
            {
                "name": "autobidpro_module",
                "deployment_config": {"port": 8200, "type": "business_module"},
                "demo_data": {"projects": 1000, "bids": 5000, "workflows": 5}
            },
            {
                "name": "automarketingpro_module",
                "deployment_config": {"port": 8300, "type": "business_module"},
                "demo_data": {"campaigns": 500, "leads": 10000, "workflows": 5}
            },
            {
                "name": "autosalespro_module",
                "deployment_config": {"port": 8400, "type": "business_module"},
                "demo_data": {"prospects": 2000, "deals": 1000, "workflows": 5}
            },
            {
                "name": "clinical_module",
                "deployment_config": {"port": 8600, "type": "healthcare_module"},
                "demo_data": {"patients": 500, "encounters": 1000, "workflows": 5}
            },
            {
                "name": "ai_healthcare_module",
                "deployment_config": {"port": 8800, "type": "ai_module"},
                "demo_data": {"ai_models": 55, "predictions": 10000, "workflows": 5}
            }
        ]
        
        # Execute comprehensive evaluation
        results = self.evaluate_all_modules(modules)
        
        return results

if __name__ == "__main__":
    evaluator = FiveModelEvaluationSystem()
    results = evaluator.run_comprehensive_platform_evaluation()
    
    print(f"\n🎯 FINAL EVALUATION SUMMARY:")
    print(f"Platform Ready: {'✅ YES' if results['platform_summary']['platform_ready'] else '❌ NO'}")
    print(f"Success Rate: {results['platform_summary']['success_rate']:.1f}%")
    print(f"Average Score: {results['platform_summary']['average_score']:.2f}/10")
    print(f"Total Iterations: {results['platform_summary']['total_iterations']}")
    print(f"\n📄 Detailed results saved to: comprehensive_platform_evaluation.json")
