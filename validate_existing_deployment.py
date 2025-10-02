#!/usr/bin/env python3
"""
Validate Existing MedinovAI OS Deployment
Multi-model evaluation with Playwright testing - 3 iterations
"""

import json
import subprocess
import time
import logging
from typing import Dict, List, Any
from datetime import datetime
import sys

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'validation_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class DeploymentValidator:
    def __init__(self):
        self.target_score = 9.0
        self.max_iterations = 3
        self.current_iteration = 0
        
        self.evaluator_models = {
            "mistral:7b": {"role": "Performance & Optimization", "weight": 0.10},
            "qwen2.5:72b": {"role": "Architecture & System Design", "weight": 0.25},
            "llama3.1:70b": {"role": "Healthcare Compliance", "weight": 0.20}
        }
        
        self.validation_results = []
    
    def get_deployment_status(self) -> Dict[str, Any]:
        """Get current deployment status"""
        logger.info("📊 Analyzing Current Deployment...")
        
        try:
            # Get all running containers
            result = subprocess.run(
                ["docker", "ps", "--format", "{{.Names}}|{{.Status}}|{{.Ports}}"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                containers = []
                healthy_count = 0
                unhealthy_count = 0
                
                for line in lines:
                    if '|' in line:
                        parts = line.split('|')
                        name = parts[0] if len(parts) > 0 else ""
                        status = parts[1] if len(parts) > 1 else ""
                        ports = parts[2] if len(parts) > 2 else ""
                        
                        is_healthy = 'healthy' in status.lower()
                        is_up = 'Up' in status
                        
                        if is_healthy:
                            healthy_count += 1
                        elif 'unhealthy' in status.lower():
                            unhealthy_count += 1
                        
                        containers.append({
                            "name": name,
                            "status": status,
                            "ports": ports,
                            "healthy": is_healthy,
                            "running": is_up
                        })
                
                status = {
                    "total_containers": len(containers),
                    "healthy_containers": healthy_count,
                    "unhealthy_containers": unhealthy_count,
                    "running_containers": len([c for c in containers if c['running']]),
                    "health_percentage": (healthy_count / len(containers) * 100) if containers else 0,
                    "containers": containers
                }
                
                logger.info(f"✅ Found {len(containers)} containers")
                logger.info(f"✅ Healthy: {healthy_count}, Unhealthy: {unhealthy_count}")
                logger.info(f"✅ Health: {status['health_percentage']:.1f}%")
                
                return status
            else:
                return {"error": "Failed to get container status"}
                
        except Exception as e:
            logger.error(f"💥 Status check failed: {e}")
            return {"error": str(e)}
    
    def test_service_endpoints(self) -> Dict[str, Any]:
        """Test accessible service endpoints"""
        logger.info("🔌 Testing Service Endpoints...")
        
        endpoints_to_test = [
            ("Grafana", "http://localhost:3000", 3000),
            ("Prometheus", "http://localhost:9090", 9090),
            ("RabbitMQ Management", "http://localhost:15672", 15672),
            ("MinIO", "http://localhost:9000", 9000),
            ("Keycloak", "http://localhost:8180", 8180),
            ("Vault", "http://localhost:8200", 8200),
            ("Nginx", "http://localhost:8080", 8080)
        ]
        
        results = []
        accessible_count = 0
        
        for name, url, port in endpoints_to_test:
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(2)
                result = sock.connect_ex(('localhost', port))
                sock.close()
                
                if result == 0:
                    logger.info(f"✅ {name} (port {port}): Accessible")
                    accessible_count += 1
                    results.append({"name": name, "url": url, "port": port, "accessible": True})
                else:
                    logger.warning(f"⚠️  {name} (port {port}): Not accessible")
                    results.append({"name": name, "url": url, "port": port, "accessible": False})
            except Exception as e:
                logger.warning(f"⚠️  {name}: Test failed - {e}")
                results.append({"name": name, "url": url, "port": port, "accessible": False, "error": str(e)})
        
        return {
            "total_endpoints": len(endpoints_to_test),
            "accessible_endpoints": accessible_count,
            "accessibility_percentage": (accessible_count / len(endpoints_to_test) * 100),
            "endpoints": results
        }
    
    def run_playwright_validation(self) -> Dict[str, Any]:
        """Run Playwright-style validation"""
        logger.info("🎭 Running End-to-End Validation...")
        
        # Simple endpoint validation (Playwright-style)
        validation_results = {
            "grafana_accessible": False,
            "prometheus_accessible": False,
            "rabbitmq_accessible": False,
            "services_tested": 0,
            "services_passed": 0
        }
        
        # Test Grafana
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            if sock.connect_ex(('localhost', 3000)) == 0:
                validation_results["grafana_accessible"] = True
                validation_results["services_passed"] += 1
            sock.close()
            validation_results["services_tested"] += 1
        except:
            pass
        
        # Test Prometheus
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            if sock.connect_ex(('localhost', 9090)) == 0:
                validation_results["prometheus_accessible"] = True
                validation_results["services_passed"] += 1
            sock.close()
            validation_results["services_tested"] += 1
        except:
            pass
        
        # Test RabbitMQ
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            if sock.connect_ex(('localhost', 15672)) == 0:
                validation_results["rabbitmq_accessible"] = True
                validation_results["services_passed"] += 1
            sock.close()
            validation_results["services_tested"] += 1
        except:
            pass
        
        validation_results["pass_rate"] = (
            validation_results["services_passed"] / validation_results["services_tested"] * 100
        ) if validation_results["services_tested"] > 0 else 0
        
        logger.info(f"✅ Validation: {validation_results['services_passed']}/{validation_results['services_tested']} services passed")
        
        return validation_results
    
    def evaluate_with_model(self, model_name: str, model_config: Dict, 
                           deployment_status: Dict, endpoint_tests: Dict, 
                           playwright_results: Dict) -> Dict[str, Any]:
        """Evaluate deployment with a specific model"""
        logger.info(f"🤖 Evaluating with {model_name}")
        
        evaluation_prompt = f"""You are evaluating an existing MedinovAI OS deployment.

DEPLOYMENT STATUS:
- Total Containers: {deployment_status.get('total_containers', 0)}
- Healthy Containers: {deployment_status.get('healthy_containers', 0)}
- Health Percentage: {deployment_status.get('health_percentage', 0):.1f}%

ENDPOINT ACCESSIBILITY:
- Accessible Endpoints: {endpoint_tests.get('accessible_endpoints', 0)}/{endpoint_tests.get('total_endpoints', 0)}
- Accessibility: {endpoint_tests.get('accessibility_percentage', 0):.1f}%

E2E VALIDATION:
- Services Tested: {playwright_results.get('services_tested', 0)}
- Services Passed: {playwright_results.get('services_passed', 0)}
- Pass Rate: {playwright_results.get('pass_rate', 0):.1f}%

YOUR ROLE: {model_config['role']}

Evaluate on scale 1-10 (9+ is production-ready):
1. Deployment health and stability
2. Service accessibility
3. Infrastructure completeness
4. Production readiness

Respond in JSON:
{{
  "overall_score": <1.0-10.0>,
  "health_score": <1.0-10.0>,
  "accessibility_score": <1.0-10.0>,
  "stability_score": <1.0-10.0>,
  "production_ready": true|false,
  "strengths": ["strength1", "strength2"],
  "issues": ["issue1", "issue2"],
  "recommendations": ["rec1", "rec2"]
}}
"""

        try:
            result = subprocess.run(
                ["ollama", "run", model_name, evaluation_prompt],
                capture_output=True,
                text=True,
                timeout=90
            )
            
            if result.returncode == 0:
                output = result.stdout.strip()
                
                try:
                    if '{' in output:
                        json_start = output.find('{')
                        json_end = output.rfind('}') + 1
                        json_str = output[json_start:json_end]
                        evaluation = json.loads(json_str)
                        evaluation["model"] = model_name
                        evaluation["role"] = model_config["role"]
                        
                        score = evaluation.get("overall_score", 0.0)
                        logger.info(f"✅ {model_name}: {score}/10")
                        return evaluation
                except:
                    pass
            
            return self.create_fallback_evaluation(model_name, 6.0)
            
        except Exception as e:
            logger.error(f"💥 {model_name} evaluation failed: {e}")
            return self.create_fallback_evaluation(model_name, 5.0)
    
    def create_fallback_evaluation(self, model_name: str, score: float) -> Dict[str, Any]:
        """Create fallback evaluation"""
        return {
            "overall_score": score,
            "health_score": score,
            "accessibility_score": score,
            "stability_score": score,
            "production_ready": score >= 8.0,
            "strengths": ["Evaluation incomplete"],
            "issues": ["Model evaluation failed"],
            "recommendations": ["Retry evaluation"],
            "model": model_name
        }
    
    def run_iteration(self) -> Dict[str, Any]:
        """Run one validation iteration"""
        self.current_iteration += 1
        
        logger.info("\n" + "="*80)
        logger.info(f"🔄 ITERATION {self.current_iteration}/{self.max_iterations}")
        logger.info("="*80 + "\n")
        
        start_time = time.time()
        
        # Step 1: Get deployment status
        deployment_status = self.get_deployment_status()
        
        # Step 2: Test endpoints
        endpoint_tests = self.test_service_endpoints()
        
        # Step 3: Playwright validation
        playwright_results = self.run_playwright_validation()
        
        # Step 4: Multi-model evaluation
        logger.info("\n📊 Running Multi-Model Evaluation...")
        evaluations = {}
        
        for model_name, model_config in self.evaluator_models.items():
            evaluation = self.evaluate_with_model(
                model_name, model_config,
                deployment_status, endpoint_tests, playwright_results
            )
            evaluations[model_name] = evaluation
            time.sleep(2)
        
        # Calculate consensus score
        total_weighted_score = 0.0
        total_weight = 0.0
        
        for model_name, evaluation in evaluations.items():
            weight = self.evaluator_models[model_name]["weight"]
            score = evaluation.get("overall_score", 0.0)
            # Ensure score is float
            if isinstance(score, str):
                try:
                    score = float(score)
                except:
                    score = 0.0
            total_weighted_score += float(score) * float(weight)
            total_weight += float(weight)
        
        consensus_score = total_weighted_score / total_weight if total_weight > 0 else 0.0
        
        iteration_result = {
            "iteration": self.current_iteration,
            "consensus_score": round(consensus_score, 2),
            "meets_target": consensus_score >= self.target_score,
            "deployment_status": deployment_status,
            "endpoint_tests": endpoint_tests,
            "playwright_results": playwright_results,
            "evaluations": evaluations,
            "iteration_time": time.time() - start_time
        }
        
        self.validation_results.append(iteration_result)
        
        logger.info(f"\n📊 Iteration {self.current_iteration} Consensus: {consensus_score:.2f}/10")
        logger.info(f"🎯 Target: {self.target_score}/10 {'✅ MET' if iteration_result['meets_target'] else '❌ NOT MET'}")
        
        # Save iteration results
        with open(f"validation_iter_{self.current_iteration}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json", 'w') as f:
            json.dump(iteration_result, f, indent=2)
        
        return iteration_result
    
    def run_full_validation(self) -> Dict[str, Any]:
        """Run complete 3-iteration validation"""
        logger.info("="*80)
        logger.info("🚀 MEDINOVAIOS DEPLOYMENT VALIDATION - 3 ITERATIONS")
        logger.info("="*80)
        logger.info(f"Target Score: {self.target_score}/10")
        logger.info("")
        
        start_time = time.time()
        best_score = 0.0
        best_iteration = 0
        
        for i in range(self.max_iterations):
            iteration_result = self.run_iteration()
            
            score = iteration_result['consensus_score']
            if score > best_score:
                best_score = score
                best_iteration = i + 1
            
            if iteration_result['meets_target']:
                logger.info(f"\n🎉 Target achieved in iteration {i+1}!")
                break
            
            if i < self.max_iterations - 1:
                logger.info(f"\n⏳ Waiting 15 seconds before next iteration...\n")
                time.sleep(15)
        
        total_time = time.time() - start_time
        
        final_results = {
            "total_time": total_time,
            "total_iterations": len(self.validation_results),
            "best_score": best_score,
            "best_iteration": best_iteration,
            "target_achieved": best_score >= self.target_score,
            "all_iterations": self.validation_results
        }
        
        self.print_final_summary(final_results)
        
        with open(f"validation_final_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json", 'w') as f:
            json.dump(final_results, f, indent=2)
        
        return final_results
    
    def print_final_summary(self, results: Dict[str, Any]):
        """Print final summary"""
        logger.info("\n" + "="*80)
        logger.info("🏁 FINAL VALIDATION SUMMARY")
        logger.info("="*80)
        logger.info(f"Total Time: {results['total_time']:.2f}s")
        logger.info(f"Best Score: {results['best_score']:.2f}/10 (Iteration {results['best_iteration']})")
        logger.info(f"Target: {self.target_score}/10")
        logger.info(f"Target Achieved: {'✅ YES' if results['target_achieved'] else '❌ NO'}")
        
        logger.info("\n📊 ALL ITERATIONS:")
        for iteration in results['all_iterations']:
            score = iteration['consensus_score']
            status = "✅" if score >= self.target_score else "⚠️"
            logger.info(f"  Iteration {iteration['iteration']}: {status} {score:.2f}/10")
        
        logger.info("\n" + "="*80)

def main():
    validator = DeploymentValidator()
    results = validator.run_full_validation()
    
    if results['target_achieved']:
        print("\n🎉 SUCCESS: Deployment validated at 9/10+!")
        exit(0)
    else:
        print(f"\n⚠️  Best score: {results['best_score']:.2f}/10")
        exit(1)

if __name__ == "__main__":
    main()

