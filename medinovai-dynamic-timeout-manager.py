#!/usr/bin/env python3
"""
MedinovAI Dynamic Timeout Manager
Optimizes timeouts and resource allocation for Mac Studio M3 Ultra
"""

import os
import sys
import json
import time
import psutil
import subprocess
import threading
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from pathlib import Path

@dataclass
class SystemResources:
    """System resource information"""
    total_cpu_cores: int
    total_memory_gb: int
    gpu_cores: int
    neural_cores: int
    current_cpu_usage: float
    current_memory_usage: float
    available_memory_gb: float

@dataclass
class ModelConfig:
    """Model configuration for dynamic timeouts"""
    name: str
    size_gb: float
    cpu_intensive: bool
    memory_intensive: bool
    base_timeout: int
    max_timeout: int
    min_timeout: int

class MedinovAIDynamicTimeoutManager:
    """Dynamic timeout and resource manager for MedinovAI system"""
    
    def __init__(self):
        self.system_info = self._get_system_info()
        self.model_configs = self._load_model_configs()
        self.active_models = {}
        self.resource_monitor = threading.Thread(target=self._monitor_resources, daemon=True)
        self.resource_monitor.start()
        
    def _get_system_info(self) -> SystemResources:
        """Get current system resource information"""
        try:
            # Get CPU info
            cpu_count = os.cpu_count()
            
            # Get memory info
            memory = psutil.virtual_memory()
            total_memory_gb = memory.total / (1024**3)
            available_memory_gb = memory.available / (1024**3)
            current_memory_usage = memory.percent
            
            # Get CPU usage
            cpu_usage = psutil.cpu_percent(interval=1)
            
            # Mac Studio M3 Ultra specific
            gpu_cores = 80  # M3 Ultra GPU cores
            neural_cores = 32  # M3 Ultra Neural Engine cores
            
            return SystemResources(
                total_cpu_cores=cpu_count,
                total_memory_gb=total_memory_gb,
                gpu_cores=gpu_cores,
                neural_cores=neural_cores,
                current_cpu_usage=cpu_usage,
                current_memory_usage=current_memory_usage,
                available_memory_gb=available_memory_gb
            )
        except Exception as e:
            print(f"Error getting system info: {e}")
            # Fallback values for Mac Studio M3 Ultra
            return SystemResources(
                total_cpu_cores=32,
                total_memory_gb=512,
                gpu_cores=80,
                neural_cores=32,
                current_cpu_usage=50.0,
                current_memory_usage=80.0,
                available_memory_gb=100.0
            )
    
    def _load_model_configs(self) -> Dict[str, ModelConfig]:
        """Load model configurations with dynamic timeout settings"""
        return {
            "deepseek-r1:70b": ModelConfig(
                name="deepseek-r1:70b",
                size_gb=42.0,
                cpu_intensive=True,
                memory_intensive=True,
                base_timeout=300,  # 5 minutes
                max_timeout=1800,  # 30 minutes
                min_timeout=120    # 2 minutes
            ),
            "qwen2.5:72b": ModelConfig(
                name="qwen2.5:72b",
                size_gb=47.0,
                cpu_intensive=True,
                memory_intensive=True,
                base_timeout=300,
                max_timeout=1800,
                min_timeout=120
            ),
            "qwen3:30b-a3b": ModelConfig(
                name="qwen3:30b-a3b",
                size_gb=19.0,
                cpu_intensive=False,
                memory_intensive=True,
                base_timeout=180,  # 3 minutes
                max_timeout=900,   # 15 minutes
                min_timeout=60     # 1 minute
            ),
            "llama3.1:70b": ModelConfig(
                name="llama3.1:70b",
                size_gb=42.0,
                cpu_intensive=True,
                memory_intensive=True,
                base_timeout=300,
                max_timeout=1800,
                min_timeout=120
            ),
            "codellama:70b": ModelConfig(
                name="codellama:70b",
                size_gb=38.0,
                cpu_intensive=True,
                memory_intensive=True,
                base_timeout=300,
                max_timeout=1800,
                min_timeout=120
            ),
            "qwen2.5:32b": ModelConfig(
                name="qwen2.5:32b",
                size_gb=19.0,
                cpu_intensive=False,
                memory_intensive=True,
                base_timeout=180,
                max_timeout=900,
                min_timeout=60
            ),
            "qwen2.5:14b": ModelConfig(
                name="qwen2.5:14b",
                size_gb=9.0,
                cpu_intensive=False,
                memory_intensive=False,
                base_timeout=120,  # 2 minutes
                max_timeout=600,   # 10 minutes
                min_timeout=30     # 30 seconds
            ),
            "qwen2.5:7b": ModelConfig(
                name="qwen2.5:7b",
                size_gb=4.7,
                cpu_intensive=False,
                memory_intensive=False,
                base_timeout=90,   # 1.5 minutes
                max_timeout=300,   # 5 minutes
                min_timeout=20     # 20 seconds
            ),
            "deepseek-coder:latest": ModelConfig(
                name="deepseek-coder:latest",
                size_gb=0.8,
                cpu_intensive=False,
                memory_intensive=False,
                base_timeout=60,   # 1 minute
                max_timeout=180,   # 3 minutes
                min_timeout=15     # 15 seconds
            ),
            "mistral:latest": ModelConfig(
                name="mistral:latest",
                size_gb=4.4,
                cpu_intensive=False,
                memory_intensive=False,
                base_timeout=90,
                max_timeout=300,
                min_timeout=20
            )
        }
    
    def _monitor_resources(self):
        """Continuously monitor system resources"""
        while True:
            try:
                self.system_info = self._get_system_info()
                time.sleep(5)  # Update every 5 seconds
            except Exception as e:
                print(f"Error monitoring resources: {e}")
                time.sleep(10)
    
    def calculate_dynamic_timeout(self, model_name: str, task_complexity: str = "medium") -> int:
        """Calculate dynamic timeout based on current system resources and model"""
        if model_name not in self.model_configs:
            # Default timeout for unknown models
            return 300
        
        config = self.model_configs[model_name]
        
        # Base timeout from model config
        base_timeout = config.base_timeout
        
        # Adjust based on system load
        cpu_factor = 1.0
        memory_factor = 1.0
        
        # CPU load adjustment
        if self.system_info.current_cpu_usage > 80:
            cpu_factor = 1.5  # Increase timeout when CPU is busy
        elif self.system_info.current_cpu_usage < 30:
            cpu_factor = 0.8  # Decrease timeout when CPU is idle
        
        # Memory load adjustment
        if self.system_info.current_memory_usage > 85:
            memory_factor = 1.3  # Increase timeout when memory is tight
        elif self.system_info.current_memory_usage < 50:
            memory_factor = 0.9  # Decrease timeout when memory is available
        
        # Task complexity adjustment
        complexity_factors = {
            "simple": 0.5,
            "medium": 1.0,
            "complex": 1.5,
            "very_complex": 2.0
        }
        complexity_factor = complexity_factors.get(task_complexity, 1.0)
        
        # Calculate final timeout
        dynamic_timeout = int(base_timeout * cpu_factor * memory_factor * complexity_factor)
        
        # Ensure timeout is within bounds
        dynamic_timeout = max(config.min_timeout, min(dynamic_timeout, config.max_timeout))
        
        return dynamic_timeout
    
    def get_optimal_model_allocation(self) -> Dict[str, int]:
        """Get optimal model allocation based on current resources"""
        available_memory = self.system_info.available_memory_gb
        available_cpu = 100 - self.system_info.current_cpu_usage
        
        allocation = {}
        
        # Prioritize models based on current system state
        if available_memory > 200:  # High memory available
            allocation["large_models"] = min(3, int(available_memory / 50))
        elif available_memory > 100:  # Medium memory available
            allocation["medium_models"] = min(4, int(available_memory / 25))
        else:  # Low memory available
            allocation["small_models"] = min(6, int(available_memory / 10))
        
        return allocation
    
    def get_ollama_timeout_config(self) -> Dict[str, any]:
        """Get Ollama timeout configuration"""
        return {
            "timeout": {
                "default": self.calculate_dynamic_timeout("qwen2.5:7b", "medium"),
                "models": {
                    model: self.calculate_dynamic_timeout(model, "medium")
                    for model in self.model_configs.keys()
                }
            },
            "resources": {
                "max_concurrent_models": self._calculate_max_concurrent_models(),
                "memory_per_model": self._calculate_memory_per_model(),
                "cpu_allocation": self._calculate_cpu_allocation()
            },
            "system": {
                "total_memory_gb": self.system_info.total_memory_gb,
                "available_memory_gb": self.system_info.available_memory_gb,
                "cpu_usage_percent": self.system_info.current_cpu_usage,
                "memory_usage_percent": self.system_info.current_memory_usage
            }
        }
    
    def _calculate_max_concurrent_models(self) -> int:
        """Calculate maximum concurrent models based on available resources"""
        available_memory = self.system_info.available_memory_gb
        
        # Conservative calculation: each large model needs ~50GB, medium ~25GB, small ~10GB
        if available_memory > 200:
            return min(4, int(available_memory / 50))
        elif available_memory > 100:
            return min(6, int(available_memory / 25))
        else:
            return min(8, int(available_memory / 10))
    
    def _calculate_memory_per_model(self) -> Dict[str, int]:
        """Calculate memory allocation per model type"""
        available_memory = self.system_info.available_memory_gb
        max_models = self._calculate_max_concurrent_models()
        
        memory_per_model = available_memory / max_models if max_models > 0 else 50
        
        return {
            "large_models": int(memory_per_model * 1.5),  # 70B+ models
            "medium_models": int(memory_per_model),       # 30B models
            "small_models": int(memory_per_model * 0.5)   # 7B models
        }
    
    def _calculate_cpu_allocation(self) -> Dict[str, float]:
        """Calculate CPU allocation strategy"""
        available_cpu = 100 - self.system_info.current_cpu_usage
        
        return {
            "background_tasks": min(20, available_cpu * 0.2),
            "model_inference": min(60, available_cpu * 0.6),
            "system_overhead": min(20, available_cpu * 0.2)
        }
    
    def generate_ollama_config(self) -> str:
        """Generate Ollama configuration with dynamic timeouts"""
        config = self.get_ollama_timeout_config()
        
        ollama_config = f"""# MedinovAI Dynamic Ollama Configuration
# Generated on: {time.strftime('%Y-%m-%d %H:%M:%S')}
# System: Mac Studio M3 Ultra (32 CPU, 80 GPU, 32 Neural, 512GB RAM)

# Dynamic timeout configuration
export OLLAMA_TIMEOUT_DEFAULT={config['timeout']['default']}
export OLLAMA_MAX_CONCURRENT_MODELS={config['resources']['max_concurrent_models']}
export OLLAMA_MEMORY_PER_MODEL={config['resources']['memory_per_model']['medium_models']}

# Model-specific timeouts
"""
        
        for model, timeout in config['timeout']['models'].items():
            ollama_config += f"export OLLAMA_TIMEOUT_{model.upper().replace(':', '_').replace('-', '_')}={timeout}\n"
        
        ollama_config += f"""
# System resource monitoring
export OLLAMA_CPU_THRESHOLD=80
export OLLAMA_MEMORY_THRESHOLD=85
export OLLAMA_GPU_THRESHOLD=90

# Performance optimization
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_MAX_LOADED_MODELS=3
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_GPU_LAYERS=-1
"""
        
        return ollama_config
    
    def save_config(self, filepath: str = "medinovai-dynamic-config.env"):
        """Save dynamic configuration to file"""
        config = self.get_ollama_timeout_config()
        ollama_config = self.generate_ollama_config()
        
        # Save JSON config
        with open(f"{filepath}.json", 'w') as f:
            json.dump(config, f, indent=2)
        
        # Save environment config
        with open(filepath, 'w') as f:
            f.write(ollama_config)
        
        print(f"Dynamic configuration saved to {filepath} and {filepath}.json")
    
    def apply_config(self):
        """Apply dynamic configuration to current session"""
        config = self.generate_ollama_config()
        
        # Write to temporary file and source it
        with open("/tmp/medinovai-dynamic-config.env", 'w') as f:
            f.write(config)
        
        # Source the configuration
        subprocess.run(["source", "/tmp/medinovai-dynamic-config.env"], shell=True)
        print("Dynamic configuration applied to current session")

def main():
    """Main function to run the dynamic timeout manager"""
    manager = MedinovAIDynamicTimeoutManager()
    
    print("=== MedinovAI Dynamic Timeout Manager ===")
    print(f"System: Mac Studio M3 Ultra")
    print(f"CPU Cores: {manager.system_info.total_cpu_cores}")
    print(f"Memory: {manager.system_info.total_memory_gb:.1f}GB")
    print(f"GPU Cores: {manager.system_info.gpu_cores}")
    print(f"Neural Cores: {manager.system_info.neural_cores}")
    print()
    
    print("=== Current Resource Usage ===")
    print(f"CPU Usage: {manager.system_info.current_cpu_usage:.1f}%")
    print(f"Memory Usage: {manager.system_info.current_memory_usage:.1f}%")
    print(f"Available Memory: {manager.system_info.available_memory_gb:.1f}GB")
    print()
    
    print("=== Dynamic Timeout Calculations ===")
    for model in ["deepseek-r1:70b", "qwen2.5:72b", "qwen3:30b-a3b", "qwen2.5:7b"]:
        timeout = manager.calculate_dynamic_timeout(model, "medium")
        print(f"{model}: {timeout}s")
    print()
    
    print("=== Optimal Model Allocation ===")
    allocation = manager.get_optimal_model_allocation()
    for model_type, count in allocation.items():
        print(f"{model_type}: {count} models")
    print()
    
    # Save configuration
    manager.save_config()
    
    # Apply configuration
    manager.apply_config()
    
    print("=== Configuration Complete ===")
    print("Dynamic timeouts are now active and will adjust based on system load.")

if __name__ == "__main__":
    main()

