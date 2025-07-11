#!/usr/bin/env python3
"""
Performance monitoring script for medinovai-real-time-stream-bus
"""

import time
import psutil
import requests
import json
from datetime import datetime
from pathlib import Path

class PerformanceMonitor:
    def __init__(self):
        self.metrics = []
        self.config = self.load_config()
    
    def load_config(self):
        config_path = Path("monitoring/performance.yaml")
        if config_path.exists():
            import yaml
            with open(config_path) as f:
                return yaml.safe_load(f)
        return {}
    
    def collect_system_metrics(self):
        """Collect system performance metrics"""
        return {
            "timestamp": datetime.now().isoformat(),
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_usage": psutil.disk_usage('/').percent
        }
    
    def collect_application_metrics(self):
        """Collect application-specific metrics"""
        # Add application-specific metric collection here
        return {
            "timestamp": datetime.now().isoformat(),
            "active_connections": 0,
            "requests_per_second": 0,
            "error_rate": 0.0
        }
    
    def run(self):
        """Run the performance monitoring"""
        print(f"Starting performance monitoring for {repo_name}...")
        
        while True:
            try:
                system_metrics = self.collect_system_metrics()
                app_metrics = self.collect_application_metrics()
                
                combined_metrics = {**system_metrics, **app_metrics}
                self.metrics.append(combined_metrics)
                
                # Log metrics
                print(f"Metrics: {combined_metrics}")
                
                # Check thresholds
                self.check_thresholds(combined_metrics)
                
                time.sleep(60)  # Collect every minute
                
            except KeyboardInterrupt:
                print("\nStopping performance monitoring...")
                break
            except Exception as e:
                print(f"Error collecting metrics: {e}")
                time.sleep(60)
    
    def check_thresholds(self, metrics):
        """Check if metrics exceed thresholds"""
        thresholds = self.config.get("monitoring", {}).get("thresholds", {})
        
        if metrics["cpu_percent"] > thresholds.get("cpu_usage", 70):
            print(f"WARNING: CPU usage {metrics['cpu_percent']}% exceeds threshold")
        
        if metrics["memory_percent"] > thresholds.get("memory_usage", 80):
            print(f"WARNING: Memory usage {metrics['memory_percent']}% exceeds threshold")

if __name__ == "__main__":
    monitor = PerformanceMonitor()
    monitor.run()
