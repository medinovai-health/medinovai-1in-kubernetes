#!/usr/bin/env python3
"""
Parallel Processing Maximizer - Mac Studio M3 Ultra
Maximizes hardware utilization with intelligent agent swarm distribution
"""

import psutil
import subprocess
import threading
import time
import logging
from typing import Dict, List, Any
from datetime import datetime
import json

logger = logging.getLogger(__name__)

class ParallelProcessingMaximizer:
    def __init__(self):
        self.max_cpu_cores = 32
        self.max_memory_gb = 512
        self.max_gpu_cores = 80
        self.max_neural_cores = 32
        
        # Current utilization tracking
        self.current_cpu_usage = 0
        self.current_memory_usage = 0
        self.active_processes = {}
        self.ollama_instances = {}
        
    def get_system_resources(self) -> Dict[str, Any]:
        """Get current system resource utilization"""
        
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        
        return {
            "cpu_percent": cpu_percent,
            "cpu_cores_used": (cpu_percent / 100) * self.max_cpu_cores,
            "memory_total_gb": memory.total / (1024**3),
            "memory_used_gb": memory.used / (1024**3),
            "memory_percent": memory.percent,
            "available_cpu_cores": self.max_cpu_cores - ((cpu_percent / 100) * self.max_cpu_cores),
            "available_memory_gb": (memory.total - memory.used) / (1024**3)
        }

    def optimize_ollama_instances(self) -> Dict[str, Any]:
        """Optimize Ollama model instances for maximum parallelization"""
        
        logger.info("🤖 Optimizing Ollama instances for maximum parallel processing")
        
        # Model distribution strategy
        model_instances = {
            "qwen2.5:72b": {
                "instances": 2,  # Heavy model, limited instances
                "memory_per_instance": 25,  # GB
                "cpu_cores_per_instance": 4
            },
            "llama3.1:70b": {
                "instances": 2,  # Heavy model, limited instances
                "memory_per_instance": 22,  # GB
                "cpu_cores_per_instance": 4
            },
            "codellama:34b": {
                "instances": 4,  # Medium model, more instances
                "memory_per_instance": 12,  # GB
                "cpu_cores_per_instance": 2
            },
            "qwen2.5:32b": {
                "instances": 6,  # Medium model, more instances
                "memory_per_instance": 10,  # GB
                "cpu_cores_per_instance": 2
            },
            "deepseek-coder:latest": {
                "instances": 12,  # Light model, many instances
                "memory_per_instance": 3,   # GB
                "cpu_cores_per_instance": 1
            }
        }
        
        # Calculate total resource requirements
        total_memory_needed = sum(
            config["instances"] * config["memory_per_instance"]
            for config in model_instances.values()
        )
        
        total_cpu_cores_needed = sum(
            config["instances"] * config["cpu_cores_per_instance"] 
            for config in model_instances.values()
        )
        
        logger.info(f"📊 Resource requirements: {total_memory_needed}GB memory, {total_cpu_cores_needed} CPU cores")
        logger.info(f"📊 Available resources: {self.max_memory_gb}GB memory, {self.max_cpu_cores} CPU cores")
        
        if total_memory_needed <= self.max_memory_gb * 0.9 and total_cpu_cores_needed <= self.max_cpu_cores:
            logger.info("✅ Resource requirements within limits - proceeding with optimization")
            return model_instances
        else:
            logger.warning("⚠️  Resource requirements exceed limits - scaling down")
            return self.scale_down_instances(model_instances)

    def scale_down_instances(self, model_instances: Dict[str, Any]) -> Dict[str, Any]:
        """Scale down instances to fit available resources"""
        
        # Reduce instances proportionally
        scale_factor = min(
            (self.max_memory_gb * 0.9) / sum(c["instances"] * c["memory_per_instance"] for c in model_instances.values()),
            self.max_cpu_cores / sum(c["instances"] * c["cpu_cores_per_instance"] for c in model_instances.values())
        )
        
        for model, config in model_instances.items():
            config["instances"] = max(1, int(config["instances"] * scale_factor))
        
        logger.info(f"📉 Scaled down instances by factor {scale_factor:.2f}")
        return model_instances

    def deploy_parallel_ollama_instances(self, model_instances: Dict[str, Any]):
        """Deploy multiple Ollama instances for parallel processing"""
        
        logger.info("🚀 Deploying parallel Ollama instances...")
        
        instance_id = 0
        for model_name, config in model_instances.items():
            for i in range(config["instances"]):
                instance_id += 1
                port = 11434 + instance_id
                
                # Start Ollama instance
                try:
                    # Create Docker container for Ollama instance
                    container_name = f"ollama-{model_name.replace(':', '-').replace('.', '-')}-{i+1}"
                    
                    subprocess.run([
                        "docker", "run", "-d",
                        "--name", container_name,
                        "--network", "medinovai_ai",
                        "-p", f"{port}:11434",
                        "-v", f"ollama-{instance_id}:/root/.ollama",
                        "-e", "OLLAMA_HOST=0.0.0.0",
                        "ollama/ollama:latest"
                    ], check=True, capture_output=True)
                    
                    # Wait for container to start
                    time.sleep(5)
                    
                    # Pull model
                    subprocess.run([
                        "docker", "exec", container_name,
                        "ollama", "pull", model_name
                    ], check=True, capture_output=True)
                    
                    self.ollama_instances[f"{model_name}_{i+1}"] = {
                        "container_name": container_name,
                        "port": port,
                        "model": model_name,
                        "status": "ready"
                    }
                    
                    logger.info(f"✅ Deployed {model_name} instance {i+1} on port {port}")
                    
                except Exception as e:
                    logger.error(f"❌ Failed to deploy {model_name} instance {i+1}: {e}")
        
        logger.info(f"🤖 Deployed {len(self.ollama_instances)} Ollama instances for maximum parallel processing")

    def monitor_parallel_processing(self):
        """Monitor parallel processing performance"""
        
        def monitoring_loop():
            while True:
                try:
                    resources = self.get_system_resources()
                    
                    logger.info("📊 =" * 60)
                    logger.info("📊 PARALLEL PROCESSING MONITOR")
                    logger.info("📊 =" * 60)
                    logger.info(f"📊 CPU Usage: {resources['cpu_percent']:.1f}% ({resources['cpu_cores_used']:.1f}/{self.max_cpu_cores} cores)")
                    logger.info(f"📊 Memory Usage: {resources['memory_percent']:.1f}% ({resources['memory_used_gb']:.1f}/{resources['memory_total_gb']:.1f} GB)")
                    logger.info(f"📊 Available CPU: {resources['available_cpu_cores']:.1f} cores")
                    logger.info(f"📊 Available Memory: {resources['available_memory_gb']:.1f} GB")
                    logger.info(f"📊 Ollama Instances: {len(self.ollama_instances)} active")
                    logger.info("📊 =" * 60)
                    
                    time.sleep(60)  # Monitor every minute
                    
                except Exception as e:
                    logger.error(f"❌ Monitoring error: {e}")
                    time.sleep(30)
        
        monitor_thread = threading.Thread(target=monitoring_loop, daemon=True)
        monitor_thread.start()
        logger.info("📊 Parallel processing monitor started")

if __name__ == "__main__":
    maximizer = ParallelProcessingMaximizer()
    
    # Optimize Ollama instances
    model_instances = maximizer.optimize_ollama_instances()
    
    # Deploy parallel instances
    maximizer.deploy_parallel_ollama_instances(model_instances)
    
    # Start monitoring
    maximizer.monitor_parallel_processing()
    
    logger.info("⚡ Parallel processing maximizer deployed and monitoring")

