#!/usr/bin/env python3
"""
Execution Status Monitor - Real-Time Status Reporting
Monitors all background processes and provides comprehensive status updates
"""

import sqlite3
import json
import time
import subprocess
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ExecutionStatusMonitor:
    def __init__(self):
        self.state_db = "global_master_state.db"
        self.start_time = datetime.now()
        
    def get_execution_status(self) -> Dict[str, Any]:
        """Get comprehensive execution status"""
        
        try:
            conn = sqlite3.connect(self.state_db)
            cursor = conn.cursor()
            
            # Get repository status
            cursor.execute('''
                SELECT status, COUNT(*) 
                FROM repositories 
                GROUP BY status
            ''')
            repo_status = dict(cursor.fetchall())
            
            # Get agent swarm status
            cursor.execute('''
                SELECT status, COUNT(*) 
                FROM agent_swarms 
                GROUP BY status
            ''')
            swarm_status = dict(cursor.fetchall())
            
            # Get recent heartbeats
            cursor.execute('''
                SELECT COUNT(*) 
                FROM heartbeats 
                WHERE timestamp > datetime('now', '-1 minute')
            ''')
            recent_heartbeats = cursor.fetchone()[0]
            
            # Get model distribution
            cursor.execute('''
                SELECT model_name, COUNT(*) 
                FROM agent_swarms 
                WHERE status = 'analyzing'
                GROUP BY model_name
            ''')
            model_distribution = dict(cursor.fetchall())
            
            conn.close()
            
            return {
                "timestamp": datetime.now().isoformat(),
                "execution_time": str(datetime.now() - self.start_time).split('.')[0],
                "repository_status": repo_status,
                "agent_swarm_status": swarm_status,
                "recent_heartbeats": recent_heartbeats,
                "model_distribution": model_distribution,
                "system_health": "operational"
            }
            
        except Exception as e:
            logger.error(f"❌ Failed to get execution status: {e}")
            return {
                "timestamp": datetime.now().isoformat(),
                "system_health": "error",
                "error": str(e)
            }

    def check_background_processes(self) -> Dict[str, bool]:
        """Check if background processes are running"""
        
        processes = {
            "global_master_orchestrator": False,
            "heartbeat_monitor": False,
            "parallel_processing_maximizer": False
        }
        
        try:
            # Check for Python processes
            result = subprocess.run([
                "ps", "aux"
            ], capture_output=True, text=True)
            
            output = result.stdout
            
            if "global_master_orchestrator.py" in output:
                processes["global_master_orchestrator"] = True
            if "agent_swarm_heartbeat_monitor.py" in output:
                processes["heartbeat_monitor"] = True
            if "parallel_processing_maximizer.py" in output:
                processes["parallel_processing_maximizer"] = True
                
        except Exception as e:
            logger.error(f"❌ Failed to check processes: {e}")
        
        return processes

    def generate_comprehensive_status_report(self):
        """Generate comprehensive status report"""
        
        # Get execution status
        status = self.get_execution_status()
        
        # Check background processes
        processes = self.check_background_processes()
        
        # Calculate progress metrics
        total_repos = sum(status["repository_status"].values())
        completed_repos = status["repository_status"].get("completed", 0)
        analyzing_repos = status["repository_status"].get("analyzing", 0)
        
        progress_percent = (completed_repos / total_repos) * 100 if total_repos > 0 else 0
        
        logger.info("🚀 " + "=" * 80)
        logger.info("🚀 COMPREHENSIVE EXECUTION STATUS REPORT")
        logger.info("🚀 " + "=" * 80)
        logger.info(f"🚀 Execution Time: {status['execution_time']}")
        logger.info(f"🚀 Overall Progress: {progress_percent:.1f}% ({completed_repos}/{total_repos} repositories)")
        logger.info(f"🚀 Currently Analyzing: {analyzing_repos} repositories")
        logger.info(f"🚀 Recent Heartbeats: {status['recent_heartbeats']} in last minute")
        logger.info("")
        
        logger.info("🤖 Background Processes:")
        for process, running in processes.items():
            status_icon = "✅" if running else "❌"
            logger.info(f"🤖   {status_icon} {process}: {'RUNNING' if running else 'STOPPED'}")
        logger.info("")
        
        logger.info("🔄 Agent Swarm Status:")
        for status_name, count in status["agent_swarm_status"].items():
            logger.info(f"🔄   {status_name}: {count} swarms")
        logger.info("")
        
        logger.info("🤖 Active Model Distribution:")
        for model, count in status["model_distribution"].items():
            logger.info(f"🤖   {model}: {count} active instances")
        logger.info("🚀 " + "=" * 80)
        
        return {
            "status": status,
            "processes": processes,
            "progress_percent": progress_percent,
            "system_health": "operational" if all(processes.values()) else "degraded"
        }

    def monitor_execution_continuously(self):
        """Monitor execution continuously with regular status reports"""
        
        logger.info("📊 Starting continuous execution monitoring...")
        
        while True:
            try:
                # Generate status report
                report = self.generate_comprehensive_status_report()
                
                # Check system health
                if report["system_health"] == "degraded":
                    logger.warning("⚠️  System health degraded - some processes may have stopped")
                
                # Save status report
                with open("execution_status_report.json", "w") as f:
                    json.dump(report, f, indent=2)
                
                # Wait before next report
                time.sleep(300)  # Report every 5 minutes
                
            except KeyboardInterrupt:
                logger.info("👤 Monitoring interrupted by user")
                break
            except Exception as e:
                logger.error(f"❌ Monitoring error: {e}")
                time.sleep(60)

if __name__ == "__main__":
    monitor = ExecutionStatusMonitor()
    
    # Generate initial status report
    initial_report = monitor.generate_comprehensive_status_report()
    
    # Start continuous monitoring
    monitor.monitor_execution_continuously()
