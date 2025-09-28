#!/usr/bin/env python3
"""
Agent Swarm Heartbeat Monitor
Monitors and reports heartbeats from every agent swarm
Provides real-time status of all parallel processing
"""

import sqlite3
import json
import time
import logging
import threading
from datetime import datetime, timedelta
from typing import Dict, List, Any
import subprocess

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AgentSwarmHeartbeatMonitor:
    def __init__(self):
        self.running = True
        self.state_db = "global_master_state.db"
        self.heartbeat_interval = 10  # seconds
        self.last_heartbeat_summary = datetime.now()
        self.max_cpu_cores = 32  # Mac Studio M3 Ultra CPU cores
        
    def start_monitoring(self):
        """Start comprehensive heartbeat monitoring"""
        
        logger.info("💓 Starting Agent Swarm Heartbeat Monitor")
        logger.info("💓 Monitoring all agent swarms with 10-second intervals")
        logger.info("💓 =" * 80)
        
        def monitoring_loop():
            while self.running:
                try:
                    # Get current heartbeats
                    heartbeats = self.get_recent_heartbeats()
                    
                    # Process and log heartbeats
                    self.process_heartbeats(heartbeats)
                    
                    # Generate summary every minute
                    if (datetime.now() - self.last_heartbeat_summary).seconds >= 60:
                        self.generate_heartbeat_summary()
                        self.last_heartbeat_summary = datetime.now()
                    
                    time.sleep(self.heartbeat_interval)
                    
                except Exception as e:
                    logger.error(f"💥 Heartbeat monitoring error: {e}")
                    time.sleep(5)
        
        # Start monitoring thread
        monitor_thread = threading.Thread(target=monitoring_loop, daemon=True)
        monitor_thread.start()
        
        logger.info("💓 Heartbeat monitoring thread started")
        return monitor_thread

    def get_recent_heartbeats(self) -> List[Dict[str, Any]]:
        """Get recent heartbeats from database"""
        
        try:
            conn = sqlite3.connect(self.state_db)
            cursor = conn.cursor()
            
            # Get heartbeats from last 30 seconds
            since_time = datetime.now() - timedelta(seconds=30)
            
            cursor.execute('''
                SELECT swarm_id, heartbeat_data, timestamp
                FROM heartbeats 
                WHERE timestamp > ?
                ORDER BY timestamp DESC
            ''', (since_time,))
            
            heartbeats = []
            for row in cursor.fetchall():
                try:
                    heartbeat_data = json.loads(row[1])
                    heartbeat_data["db_timestamp"] = row[2]
                    heartbeats.append(heartbeat_data)
                except json.JSONDecodeError:
                    continue
            
            conn.close()
            return heartbeats
            
        except Exception as e:
            logger.error(f"❌ Failed to get heartbeats: {e}")
            return []

    def process_heartbeats(self, heartbeats: List[Dict[str, Any]]):
        """Process and log individual heartbeats"""
        
        for heartbeat in heartbeats:
            swarm_id = heartbeat.get("swarm_id", "unknown")
            repository = heartbeat.get("repository", "unknown")
            model = heartbeat.get("model", "unknown")
            progress = heartbeat.get("progress", 0.0)
            phase = heartbeat.get("current_phase", "unknown")
            
            # Log heartbeat
            logger.info(f"💓 {swarm_id}: {repository} ({model}) - {phase} ({progress:.1%})")
            
            # Check for issues
            if "analysis_result" in heartbeat:
                result = heartbeat["analysis_result"]
                if result.get("global_standards_score", 0) < 7.0:
                    logger.warning(f"⚠️  {repository}: Low global standards score {result.get('global_standards_score', 0)}/10")
                
                if result.get("hardcoded_values_found"):
                    logger.warning(f"🔧 {repository}: Hardcoded values found - {len(result['hardcoded_values_found'])} issues")

    def generate_heartbeat_summary(self):
        """Generate comprehensive heartbeat summary"""
        
        try:
            # Get current system state
            resources = self.get_system_resources()
            
            # Get agent swarm status
            swarm_status = self.get_agent_swarm_status()
            
            # Get repository progress
            repo_progress = self.get_repository_progress()
            
            logger.info("💓 " + "=" * 80)
            logger.info("💓 COMPREHENSIVE HEARTBEAT SUMMARY")
            logger.info("💓 " + "=" * 80)
            logger.info(f"💓 Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            logger.info(f"💓 System CPU: {resources['cpu_percent']:.1f}% ({resources['cpu_cores_used']:.1f}/{self.max_cpu_cores} cores)")
            logger.info(f"💓 System Memory: {resources['memory_percent']:.1f}% ({resources['memory_used_gb']:.1f}/{resources['memory_total_gb']:.1f} GB)")
            logger.info(f"💓 Agent Swarms: {swarm_status['active']}/{swarm_status['total']} active")
            logger.info(f"💓 Repositories: {repo_progress['completed']}/{repo_progress['total']} completed ({repo_progress['progress']:.1f}%)")
            logger.info(f"💓 Models Active: {swarm_status['models_active']}")
            
            # Model distribution
            for model, count in swarm_status['model_distribution'].items():
                if count > 0:
                    logger.info(f"💓   {model}: {count} swarms active")
            
            logger.info("💓 " + "=" * 80)
            
        except Exception as e:
            logger.error(f"❌ Failed to generate heartbeat summary: {e}")

    def get_agent_swarm_status(self) -> Dict[str, Any]:
        """Get current agent swarm status"""
        
        try:
            conn = sqlite3.connect(self.state_db)
            cursor = conn.cursor()
            
            cursor.execute("SELECT COUNT(*) FROM agent_swarms")
            total_swarms = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM agent_swarms WHERE status = 'analyzing'")
            active_swarms = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM agent_swarms WHERE status = 'completed'")
            completed_swarms = cursor.fetchone()[0]
            
            cursor.execute("SELECT model_name, COUNT(*) FROM agent_swarms WHERE status = 'analyzing' GROUP BY model_name")
            model_distribution = dict(cursor.fetchall())
            
            conn.close()
            
            return {
                "total": total_swarms,
                "active": active_swarms,
                "completed": completed_swarms,
                "models_active": len(model_distribution),
                "model_distribution": model_distribution
            }
            
        except Exception as e:
            logger.error(f"❌ Failed to get swarm status: {e}")
            return {"total": 0, "active": 0, "completed": 0, "models_active": 0, "model_distribution": {}}

    def get_repository_progress(self) -> Dict[str, Any]:
        """Get repository analysis progress"""
        
        try:
            conn = sqlite3.connect(self.state_db)
            cursor = conn.cursor()
            
            cursor.execute("SELECT COUNT(*) FROM repositories")
            total_repos = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM repositories WHERE status = 'completed'")
            completed_repos = cursor.fetchone()[0]
            
            cursor.execute("SELECT AVG(analysis_progress) FROM repositories WHERE analysis_progress > 0")
            avg_progress = cursor.fetchone()[0] or 0.0
            
            conn.close()
            
            return {
                "total": total_repos,
                "completed": completed_repos,
                "progress": (completed_repos / total_repos) * 100 if total_repos > 0 else 0,
                "average_progress": avg_progress * 100
            }
            
        except Exception as e:
            logger.error(f"❌ Failed to get repository progress: {e}")
            return {"total": 0, "completed": 0, "progress": 0, "average_progress": 0}

    def get_system_resources(self) -> Dict[str, Any]:
        """Get current system resource utilization"""
        
        try:
            import psutil
            cpu_percent = psutil.cpu_percent(interval=0.1)
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
        except ImportError:
            # Fallback if psutil not available
            return {
                "cpu_percent": 50.0,
                "cpu_cores_used": 16.0,
                "memory_total_gb": 512.0,
                "memory_used_gb": 256.0,
                "memory_percent": 50.0,
                "available_cpu_cores": 16.0,
                "available_memory_gb": 256.0
            }

if __name__ == "__main__":
    monitor = AgentSwarmHeartbeatMonitor()
    
    try:
        # Start monitoring
        monitor_thread = monitor.start_monitoring()
        
        # Keep running
        while monitor.running:
            time.sleep(1)
            
    except KeyboardInterrupt:
        logger.info("👤 Heartbeat monitoring interrupted by user")
        monitor.running = False
    except Exception as e:
        logger.error(f"💥 Heartbeat monitoring failed: {e}")
        monitor.running = False
