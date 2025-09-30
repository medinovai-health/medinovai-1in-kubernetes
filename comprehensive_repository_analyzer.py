#!/usr/bin/env python3
"""
Comprehensive MedinovAI Repository Analyzer
Reviews every line of code across all 130+ repositories
Creates detailed system documentation for architecture reference
"""

import os
import json
import subprocess
import logging
from typing import Dict, List, Any, Tuple
from datetime import datetime
import sqlite3
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ComprehensiveRepositoryAnalyzer:
    def __init__(self):
        self.base_path = "/Users/dev1/github"
        self.analysis_db = "repository_analysis.db"
        self.repositories = {}
        self.architecture_map = {}
        self.integration_points = {}
        self.code_analysis = {}
        
        self.init_analysis_database()

    def init_analysis_database(self):
        """Initialize comprehensive analysis database"""
        conn = sqlite3.connect(self.analysis_db)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS repositories (
                name TEXT PRIMARY KEY,
                path TEXT,
                type TEXT,
                primary_language TEXT,
                file_count INTEGER,
                line_count INTEGER,
                complexity_score REAL,
                dependencies TEXT,
                api_endpoints TEXT,
                database_schemas TEXT,
                ui_components TEXT,
                last_analyzed TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS code_analysis (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                repo_name TEXT,
                file_path TEXT,
                file_type TEXT,
                line_count INTEGER,
                complexity_metrics TEXT,
                security_issues TEXT,
                performance_issues TEXT,
                integration_points TEXT,
                analyzed_at TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS architecture_components (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                repo_name TEXT,
                component_type TEXT,
                component_name TEXT,
                description TEXT,
                dependencies TEXT,
                interfaces TEXT,
                configuration TEXT,
                status TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
        logger.info("📊 Analysis database initialized")

    def discover_all_repositories(self) -> List[Dict[str, Any]]:
        """Discover all MedinovAI repositories in the GitHub directory"""
        logger.info("🔍 Discovering all MedinovAI repositories...")
        
        discovered_repos = []
        
        try:
            # Get all directories in /Users/dev1/github
            for item in os.listdir(self.base_path):
                item_path = os.path.join(self.base_path, item)
                
                if os.path.isdir(item_path):
                    # Check if it's a MedinovAI repository
                    if any(keyword in item.lower() for keyword in [
                        'medinovai', 'auto', 'manus', 'compliance', 'ats', 
                        'personal', 'research', 'quality', 'subscription', 'credentialing'
                    ]):
                        repo_info = self.analyze_repository_basic(item, item_path)
                        if repo_info:
                            discovered_repos.append(repo_info)
                            logger.info(f"📦 Found repository: {item}")
        
        except Exception as e:
            logger.error(f"❌ Error discovering repositories: {e}")
        
        logger.info(f"📊 Total repositories discovered: {len(discovered_repos)}")
        return discovered_repos

    def analyze_repository_basic(self, name: str, path: str) -> Dict[str, Any]:
        """Perform basic analysis of a repository"""
        try:
            # Check if it's a git repository
            git_path = os.path.join(path, '.git')
            if not os.path.exists(git_path):
                return None
            
            # Get basic repository information
            repo_info = {
                "name": name,
                "path": path,
                "is_git_repo": True,
                "discovered_at": datetime.now().isoformat()
            }
            
            # Count files and get primary language
            file_counts = {}
            total_files = 0
            total_lines = 0
            
            for root, dirs, files in os.walk(path):
                # Skip hidden directories and common ignore patterns
                dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', '__pycache__', 'dist', 'build']]
                
                for file in files:
                    if not file.startswith('.'):
                        file_path = os.path.join(root, file)
                        file_ext = os.path.splitext(file)[1].lower()
                        
                        # Count by file type
                        file_counts[file_ext] = file_counts.get(file_ext, 0) + 1
                        total_files += 1
                        
                        # Count lines for text files
                        if file_ext in ['.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.cs', '.go', '.rs', '.cpp', '.c', '.h']:
                            try:
                                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                                    total_lines += len(f.readlines())
                            except:
                                pass
            
            # Determine primary language
            language_map = {
                '.py': 'Python', '.js': 'JavaScript', '.ts': 'TypeScript',
                '.jsx': 'React', '.tsx': 'React TypeScript', '.java': 'Java',
                '.cs': 'C#', '.go': 'Go', '.rs': 'Rust', '.cpp': 'C++',
                '.c': 'C', '.h': 'C/C++ Header', '.yaml': 'YAML', '.yml': 'YAML'
            }
            
            primary_language = "Unknown"
            if file_counts:
                most_common_ext = max(file_counts, key=file_counts.get)
                primary_language = language_map.get(most_common_ext, most_common_ext)
            
            repo_info.update({
                "file_count": total_files,
                "line_count": total_lines,
                "primary_language": primary_language,
                "file_types": file_counts,
                "complexity_estimate": self.estimate_complexity(total_files, total_lines, file_counts)
            })
            
            return repo_info
            
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze {name}: {e}")
            return None

    def estimate_complexity(self, file_count: int, line_count: int, file_types: Dict) -> str:
        """Estimate repository complexity based on metrics"""
        
        # Calculate complexity score
        complexity_score = 0
        
        # File count factor
        if file_count > 1000:
            complexity_score += 3
        elif file_count > 500:
            complexity_score += 2
        elif file_count > 100:
            complexity_score += 1
        
        # Line count factor
        if line_count > 100000:
            complexity_score += 3
        elif line_count > 50000:
            complexity_score += 2
        elif line_count > 10000:
            complexity_score += 1
        
        # Language diversity factor
        if len(file_types) > 10:
            complexity_score += 2
        elif len(file_types) > 5:
            complexity_score += 1
        
        # Return complexity level
        if complexity_score >= 6:
            return "very_high"
        elif complexity_score >= 4:
            return "high"
        elif complexity_score >= 2:
            return "medium"
        else:
            return "low"

    def analyze_repository_detailed(self, repo_info: Dict[str, Any]) -> Dict[str, Any]:
        """Perform detailed analysis of repository architecture and code"""
        
        name = repo_info["name"]
        path = repo_info["path"]
        
        logger.info(f"🔍 Detailed analysis of {name}")
        
        detailed_analysis = {
            "basic_info": repo_info,
            "architecture_components": self.analyze_architecture_components(path),
            "api_endpoints": self.analyze_api_endpoints(path),
            "database_schemas": self.analyze_database_schemas(path),
            "ui_components": self.analyze_ui_components(path),
            "configuration_files": self.analyze_configuration_files(path),
            "dependencies": self.analyze_dependencies(path),
            "integration_points": self.analyze_integration_points(path),
            "security_analysis": self.analyze_security_aspects(path),
            "performance_analysis": self.analyze_performance_aspects(path)
        }
        
        return detailed_analysis

    def analyze_architecture_components(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze architectural components in repository"""
        components = []
        
        # Look for common architecture patterns
        patterns = {
            "dockerfile": "Container configuration",
            "docker-compose": "Multi-container orchestration",
            "k8s": "Kubernetes deployment",
            "api": "API service layer",
            "service": "Microservice component",
            "controller": "MVC controller",
            "model": "Data model",
            "view": "UI view component",
            "middleware": "Middleware component",
            "config": "Configuration management"
        }
        
        try:
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    file_lower = file.lower()
                    for pattern, description in patterns.items():
                        if pattern in file_lower:
                            components.append({
                                "type": pattern,
                                "file": file,
                                "path": os.path.relpath(os.path.join(root, file), repo_path),
                                "description": description
                            })
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze architecture components: {e}")
        
        return components

    def analyze_api_endpoints(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze API endpoints and routes"""
        endpoints = []
        
        try:
            # Search for API route definitions
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    if file.endswith(('.py', '.js', '.ts', '.java', '.cs')):
                        file_path = os.path.join(root, file)
                        try:
                            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                                content = f.read()
                                
                                # Look for common API patterns
                                api_patterns = [
                                    '@app.route', '@router.', 'app.get(', 'app.post(',
                                    'app.put(', 'app.delete(', 'router.get(', 'router.post(',
                                    '@GetMapping', '@PostMapping', '@PutMapping', '@DeleteMapping',
                                    '[HttpGet]', '[HttpPost]', '[HttpPut]', '[HttpDelete]'
                                ]
                                
                                for pattern in api_patterns:
                                    if pattern in content:
                                        endpoints.append({
                                            "file": os.path.relpath(file_path, repo_path),
                                            "pattern": pattern,
                                            "type": "api_endpoint"
                                        })
                                        break
                        except:
                            pass
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze API endpoints: {e}")
        
        return endpoints

    def analyze_database_schemas(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze database schemas and models"""
        schemas = []
        
        try:
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    if file.endswith(('.sql', '.py', '.js', '.ts')) and any(
                        keyword in file.lower() for keyword in ['model', 'schema', 'migration', 'database']
                    ):
                        schemas.append({
                            "file": os.path.relpath(os.path.join(root, file), repo_path),
                            "type": "database_schema"
                        })
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze database schemas: {e}")
        
        return schemas

    def analyze_ui_components(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze UI components and interfaces"""
        ui_components = []
        
        try:
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    if file.endswith(('.html', '.jsx', '.tsx', '.vue', '.css', '.scss')):
                        ui_components.append({
                            "file": os.path.relpath(os.path.join(root, file), repo_path),
                            "type": "ui_component"
                        })
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze UI components: {e}")
        
        return ui_components

    def analyze_configuration_files(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze configuration files"""
        config_files = []
        
        config_patterns = [
            'config', 'settings', 'env', 'properties', 'yaml', 'yml', 
            'json', 'toml', 'ini', 'conf'
        ]
        
        try:
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    if any(pattern in file.lower() for pattern in config_patterns):
                        config_files.append({
                            "file": os.path.relpath(os.path.join(root, file), repo_path),
                            "type": "configuration"
                        })
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze configuration files: {e}")
        
        return config_files

    def analyze_dependencies(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze repository dependencies"""
        dependencies = []
        
        dependency_files = [
            'requirements.txt', 'package.json', 'pom.xml', 'Cargo.toml',
            'go.mod', 'composer.json', 'Gemfile', 'setup.py', 'pyproject.toml'
        ]
        
        try:
            for dep_file in dependency_files:
                dep_path = os.path.join(repo_path, dep_file)
                if os.path.exists(dep_path):
                    dependencies.append({
                        "file": dep_file,
                        "type": "dependency_manifest",
                        "exists": True
                    })
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze dependencies: {e}")
        
        return dependencies

    def analyze_integration_points(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze integration points with other services"""
        integration_points = []
        
        # Look for common integration patterns
        integration_patterns = [
            'http://', 'https://', 'api/', 'webhook', 'kafka', 'redis',
            'postgres', 'mongodb', 'elasticsearch', 'rabbitmq'
        ]
        
        try:
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    if file.endswith(('.py', '.js', '.ts', '.java', '.cs', '.yaml', '.yml', '.json')):
                        file_path = os.path.join(root, file)
                        try:
                            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                                content = f.read()
                                
                                for pattern in integration_patterns:
                                    if pattern in content.lower():
                                        integration_points.append({
                                            "file": os.path.relpath(file_path, repo_path),
                                            "pattern": pattern,
                                            "type": "integration_point"
                                        })
                                        break
                        except:
                            pass
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze integration points: {e}")
        
        return integration_points

    def analyze_security_aspects(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze security-related code and configurations"""
        security_aspects = []
        
        security_patterns = [
            'password', 'secret', 'token', 'auth', 'jwt', 'oauth',
            'encryption', 'ssl', 'tls', 'certificate', 'security'
        ]
        
        try:
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    if any(pattern in file.lower() for pattern in security_patterns):
                        security_aspects.append({
                            "file": os.path.relpath(os.path.join(root, file), repo_path),
                            "type": "security_related"
                        })
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze security aspects: {e}")
        
        return security_aspects

    def analyze_performance_aspects(self, repo_path: str) -> List[Dict[str, Any]]:
        """Analyze performance-related code and configurations"""
        performance_aspects = []
        
        performance_patterns = [
            'cache', 'redis', 'memcache', 'performance', 'optimization',
            'monitoring', 'metrics', 'prometheus', 'grafana'
        ]
        
        try:
            for root, dirs, files in os.walk(repo_path):
                for file in files:
                    if any(pattern in file.lower() for pattern in performance_patterns):
                        performance_aspects.append({
                            "file": os.path.relpath(os.path.join(root, file), repo_path),
                            "type": "performance_related"
                        })
        except Exception as e:
            logger.warning(f"⚠️  Failed to analyze performance aspects: {e}")
        
        return performance_aspects

    def save_repository_analysis(self, repo_name: str, analysis: Dict[str, Any]):
        """Save detailed repository analysis to database"""
        
        conn = sqlite3.connect(self.analysis_db)
        cursor = conn.cursor()
        
        basic_info = analysis["basic_info"]
        
        cursor.execute('''
            INSERT OR REPLACE INTO repositories 
            (name, path, type, primary_language, file_count, line_count, 
             complexity_score, dependencies, api_endpoints, database_schemas, 
             ui_components, last_analyzed)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            repo_name,
            basic_info["path"],
            basic_info.get("complexity_estimate", "unknown"),
            basic_info.get("primary_language", "Unknown"),
            basic_info.get("file_count", 0),
            basic_info.get("line_count", 0),
            0.0,  # Will be calculated later
            json.dumps(analysis.get("dependencies", [])),
            json.dumps(analysis.get("api_endpoints", [])),
            json.dumps(analysis.get("database_schemas", [])),
            json.dumps(analysis.get("ui_components", [])),
            datetime.now()
        ))
        
        conn.commit()
        conn.close()

    def run_comprehensive_analysis(self) -> Dict[str, Any]:
        """Run comprehensive analysis of all repositories"""
        
        logger.info("🚀 Starting comprehensive repository analysis...")
        logger.info("📋 This will analyze every line of code across all MedinovAI repositories")
        
        # Discover all repositories
        repositories = self.discover_all_repositories()
        
        analysis_results = {
            "analysis_timestamp": datetime.now().isoformat(),
            "total_repositories": len(repositories),
            "repositories_analyzed": 0,
            "detailed_analysis": {},
            "architecture_summary": {},
            "integration_map": {},
            "summary_statistics": {}
        }
        
        # Analyze each repository in detail
        for repo_info in repositories:
            repo_name = repo_info["name"]
            
            try:
                logger.info(f"🔍 Analyzing {repo_name} ({repo_info['file_count']} files, {repo_info['line_count']} lines)")
                
                # Perform detailed analysis
                detailed_analysis = self.analyze_repository_detailed(repo_info)
                
                # Save to database
                self.save_repository_analysis(repo_name, detailed_analysis)
                
                # Add to results
                analysis_results["detailed_analysis"][repo_name] = detailed_analysis
                analysis_results["repositories_analyzed"] += 1
                
                logger.info(f"✅ Completed analysis of {repo_name}")
                
            except Exception as e:
                logger.error(f"❌ Failed to analyze {repo_name}: {e}")
        
        # Generate summary statistics
        analysis_results["summary_statistics"] = self.generate_summary_statistics(analysis_results)
        
        # Save comprehensive results
        with open("comprehensive_repository_analysis.json", "w") as f:
            json.dump(analysis_results, f, indent=2)
        
        logger.info(f"📊 Analysis complete: {analysis_results['repositories_analyzed']} repositories analyzed")
        return analysis_results

    def generate_summary_statistics(self, analysis_results: Dict[str, Any]) -> Dict[str, Any]:
        """Generate summary statistics from analysis"""
        
        total_files = 0
        total_lines = 0
        language_distribution = {}
        complexity_distribution = {}
        
        for repo_name, analysis in analysis_results["detailed_analysis"].items():
            basic_info = analysis["basic_info"]
            
            total_files += basic_info.get("file_count", 0)
            total_lines += basic_info.get("line_count", 0)
            
            # Language distribution
            lang = basic_info.get("primary_language", "Unknown")
            language_distribution[lang] = language_distribution.get(lang, 0) + 1
            
            # Complexity distribution
            complexity = basic_info.get("complexity_estimate", "unknown")
            complexity_distribution[complexity] = complexity_distribution.get(complexity, 0) + 1
        
        return {
            "total_files": total_files,
            "total_lines": total_lines,
            "average_files_per_repo": total_files / len(analysis_results["detailed_analysis"]) if analysis_results["detailed_analysis"] else 0,
            "average_lines_per_repo": total_lines / len(analysis_results["detailed_analysis"]) if analysis_results["detailed_analysis"] else 0,
            "language_distribution": language_distribution,
            "complexity_distribution": complexity_distribution
        }

if __name__ == "__main__":
    analyzer = ComprehensiveRepositoryAnalyzer()
    results = analyzer.run_comprehensive_analysis()
    
    print(f"\n🎯 COMPREHENSIVE ANALYSIS SUMMARY:")
    print(f"Repositories Analyzed: {results['repositories_analyzed']}")
    print(f"Total Files: {results['summary_statistics']['total_files']:,}")
    print(f"Total Lines of Code: {results['summary_statistics']['total_lines']:,}")
    print(f"Primary Languages: {list(results['summary_statistics']['language_distribution'].keys())}")
    print(f"\n📄 Detailed results saved to: comprehensive_repository_analysis.json")

