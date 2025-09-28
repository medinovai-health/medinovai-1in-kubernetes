#!/usr/bin/env python3
"""
Comprehensive Repository Cloning Script for All Discovered myonsite-healthcare Repositories
Clones all discovered repositories to organized directory structure
"""

import os
import json
import subprocess
import time
import logging
from typing import List, Dict, Set, Optional
from datetime import datetime
from pathlib import Path
import concurrent.futures
from threading import Lock

class ComprehensiveRepoCloner:
    def __init__(self, base_dir: str = "/Users/dev1/github/myonsite-healthcare"):
        self.logger = self._setup_logger()
        self.base_dir = Path(base_dir)
        self.org_name = "myonsite-healthcare"
        self.discovered_repos: List[Dict] = []
        self.clone_results: Dict[str, Dict] = {}
        self.lock = Lock()
        
        # Create base directory structure
        self._create_directory_structure()

    def _setup_logger(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

    def _create_directory_structure(self):
        """Create organized directory structure for repositories"""
        categories = [
            'core-services',
            'data-services', 
            'ui-frontend',
            'infrastructure',
            'libraries-sdks',
            'documentation',
            'tools-utilities',
            'archived'
        ]
        
        self.base_dir.mkdir(parents=True, exist_ok=True)
        for category in categories:
            (self.base_dir / category).mkdir(exist_ok=True)
        
        self.logger.info(f"✅ Created directory structure at {self.base_dir}")

    def load_discovered_repositories(self) -> List[Dict]:
        """Load discovered repositories from files"""
        self.logger.info("📂 Loading discovered repositories...")
        
        # Try to load from enhanced discovery first
        enhanced_file = Path("all_myonsite_healthcare_repos.json")
        if enhanced_file.exists():
            with open(enhanced_file, 'r') as f:
                repos = json.load(f)
                self.logger.info(f"✅ Loaded {len(repos)} repositories from enhanced discovery")
                return repos
        
        # Fallback to original discovery
        original_file = Path("all_github_medinovai_repos.json")
        if original_file.exists():
            with open(original_file, 'r') as f:
                repos = json.load(f)
                self.logger.info(f"✅ Loaded {len(repos)} repositories from original discovery")
                return repos
        
        self.logger.warning("❌ No discovery files found")
        return []

    def categorize_repository(self, repo: Dict) -> str:
        """Categorize repository based on name and description"""
        name = repo.get('name', '').lower()
        description = repo.get('description', '').lower()
        
        # Core services
        if any(keyword in name for keyword in ['api', 'auth', 'service', 'core', 'platform', 'gateway']):
            return 'core-services'
        
        # Data services
        if any(keyword in name for keyword in ['data', 'analytics', 'ml', 'ai', 'database', 'healthllm', 'edoctor', 'edc', 'etmf']):
            return 'data-services'
        
        # UI/Frontend
        if any(keyword in name for keyword in ['ui', 'frontend', 'web', 'dashboard', 'portal', 'app', 'nextjs', 'react']):
            return 'ui-frontend'
        
        # Infrastructure
        if any(keyword in name for keyword in ['infrastructure', 'terraform', 'k8s', 'kubernetes', 'docker', 'deploy', 'registry']):
            return 'infrastructure'
        
        # Libraries/SDKs
        if any(keyword in name for keyword in ['lib', 'sdk', 'utils', 'common', 'shared', 'standards']):
            return 'libraries-sdks'
        
        # Documentation
        if any(keyword in name for keyword in ['doc', 'wiki', 'guide', 'manual']):
            return 'documentation'
        
        # Tools/Utilities
        if any(keyword in name for keyword in ['tool', 'script', 'util', 'helper', 'automarketing', 'autobid', 'autosales']):
            return 'tools-utilities'
        
        # Default to core-services
        return 'core-services'

    def get_clone_url(self, repo: Dict) -> str:
        """Get appropriate clone URL"""
        clone_url = repo.get('clone_url', repo.get('cloneUrl', ''))
        if not clone_url:
            # Construct URL if not provided
            repo_name = repo.get('name', '')
            clone_url = f"https://github.com/{self.org_name}/{repo_name}.git"
        
        return clone_url

    def clone_repository(self, repo: Dict) -> Dict:
        """Clone a single repository"""
        repo_name = repo.get('name', '')
        category = self.categorize_repository(repo)
        target_dir = self.base_dir / category / repo_name
        clone_url = self.get_clone_url(repo)
        
        result = {
            'name': repo_name,
            'category': category,
            'target_dir': str(target_dir),
            'clone_url': clone_url,
            'success': False,
            'error': None,
            'size': 0
        }
        
        try:
            # Skip if already exists
            if target_dir.exists():
                self.logger.info(f"⏭️  Skipping {repo_name} (already exists)")
                result['success'] = True
                result['size'] = self._get_directory_size(target_dir)
                return result
            
            self.logger.info(f"📥 Cloning {repo_name} to {category}/")
            
            # Clone repository
            clone_result = subprocess.run([
                'git', 'clone', clone_url, str(target_dir)
            ], capture_output=True, text=True, timeout=300)
            
            if clone_result.returncode == 0:
                result['success'] = True
                result['size'] = self._get_directory_size(target_dir)
                self.logger.info(f"✅ Successfully cloned {repo_name}")
            else:
                result['error'] = clone_result.stderr
                self.logger.error(f"❌ Failed to clone {repo_name}: {clone_result.stderr}")
                
        except subprocess.TimeoutExpired:
            result['error'] = "Clone timeout (5 minutes)"
            self.logger.error(f"❌ Clone timeout for {repo_name}")
        except Exception as e:
            result['error'] = str(e)
            self.logger.error(f"❌ Error cloning {repo_name}: {e}")
        
        return result

    def _get_directory_size(self, path: Path) -> int:
        """Get directory size in bytes"""
        try:
            total_size = 0
            for file_path in path.rglob('*'):
                if file_path.is_file():
                    total_size += file_path.stat().st_size
            return total_size
        except Exception:
            return 0

    def clone_repositories_parallel(self, repos: List[Dict], max_workers: int = 5) -> Dict[str, Dict]:
        """Clone repositories in parallel"""
        self.logger.info(f"🚀 Starting parallel cloning of {len(repos)} repositories (max {max_workers} workers)")
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit all clone tasks
            future_to_repo = {
                executor.submit(self.clone_repository, repo): repo 
                for repo in repos
            }
            
            # Process completed tasks
            for future in concurrent.futures.as_completed(future_to_repo):
                repo = future_to_repo[future]
                try:
                    result = future.result()
                    with self.lock:
                        self.clone_results[result['name']] = result
                except Exception as e:
                    self.logger.error(f"❌ Exception cloning {repo.get('name', 'unknown')}: {e}")
                    with self.lock:
                        self.clone_results[repo.get('name', 'unknown')] = {
                            'name': repo.get('name', 'unknown'),
                            'success': False,
                            'error': str(e)
                        }
        
        return self.clone_results

    def generate_comprehensive_report(self) -> Dict:
        """Generate comprehensive cloning report"""
        successful = [r for r in self.clone_results.values() if r.get('success', False)]
        failed = [r for r in self.clone_results.values() if not r.get('success', False)]
        
        total_size = sum(r.get('size', 0) for r in successful)
        
        # Categorize results
        categories = {}
        for result in successful:
            category = result.get('category', 'unknown')
            if category not in categories:
                categories[category] = []
            categories[category].append(result)
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'organization': self.org_name,
            'base_directory': str(self.base_dir),
            'summary': {
                'total_repositories': len(self.discovered_repos),
                'successful_clones': len(successful),
                'failed_clones': len(failed),
                'success_rate': f"{(len(successful) / len(self.discovered_repos) * 100):.1f}%" if self.discovered_repos else "0%",
                'total_size_bytes': total_size,
                'total_size_mb': round(total_size / (1024 * 1024), 2),
                'total_size_gb': round(total_size / (1024 * 1024 * 1024), 2)
            },
            'categories': {
                category: {
                    'count': len(repos),
                    'total_size_mb': round(sum(r.get('size', 0) for r in repos) / (1024 * 1024), 2),
                    'repositories': [
                        {
                            'name': r['name'],
                            'size_mb': round(r.get('size', 0) / (1024 * 1024), 2)
                        } for r in repos
                    ]
                } for category, repos in categories.items()
            },
            'successful_repositories': [
                {
                    'name': r['name'],
                    'category': r['category'],
                    'size_mb': round(r.get('size', 0) / (1024 * 1024), 2)
                } for r in successful
            ],
            'failed_repositories': [
                {
                    'name': r['name'],
                    'error': r.get('error', 'Unknown error')
                } for r in failed
            ]
        }
        
        return report

    def save_comprehensive_report(self, report: Dict):
        """Save comprehensive cloning report to files"""
        # Save JSON report
        report_file = self.base_dir / 'comprehensive_clone_report.json'
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save markdown report
        md_file = self.base_dir / 'comprehensive_clone_report.md'
        with open(md_file, 'w') as f:
            f.write(f"# Myonsite Healthcare Comprehensive Repository Clone Report\n\n")
            f.write(f"**Date:** {report['timestamp']}\n")
            f.write(f"**Organization:** {report['organization']}\n")
            f.write(f"**Base Directory:** {report['base_directory']}\n\n")
            
            f.write(f"## Summary\n\n")
            f.write(f"- **Total Repositories:** {report['summary']['total_repositories']}\n")
            f.write(f"- **Successful Clones:** {report['summary']['successful_clones']}\n")
            f.write(f"- **Failed Clones:** {report['summary']['failed_clones']}\n")
            f.write(f"- **Success Rate:** {report['summary']['success_rate']}\n")
            f.write(f"- **Total Size:** {report['summary']['total_size_mb']} MB ({report['summary']['total_size_gb']} GB)\n\n")
            
            f.write(f"## Categories\n\n")
            for category, data in report['categories'].items():
                f.write(f"### {category.title().replace('-', ' ')} ({data['count']} repositories, {data['total_size_mb']} MB)\n")
                for repo in data['repositories']:
                    f.write(f"- **{repo['name']}** ({repo['size_mb']} MB)\n")
                f.write("\n")
            
            if report['failed_repositories']:
                f.write(f"## Failed Clones\n\n")
                for repo in report['failed_repositories']:
                    f.write(f"- **{repo['name']}:** {repo['error']}\n")
        
        self.logger.info(f"✅ Comprehensive reports saved to {report_file} and {md_file}")

    def run_comprehensive_clone_process(self):
        """Run the comprehensive repository cloning process"""
        self.logger.info("🚀 Starting comprehensive myonsite-healthcare repository cloning process")
        
        # Step 1: Load discovered repositories
        self.discovered_repos = self.load_discovered_repositories()
        if not self.discovered_repos:
            self.logger.error("❌ No repositories discovered. Cannot proceed with cloning.")
            return None
        
        self.logger.info(f"✅ Loaded {len(self.discovered_repos)} repositories for cloning")
        
        # Step 2: Clone repositories
        self.clone_repositories_parallel(self.discovered_repos)
        
        # Step 3: Generate and save comprehensive report
        report = self.generate_comprehensive_report()
        self.save_comprehensive_report(report)
        
        # Step 4: Print summary
        self.logger.info("🎉 Comprehensive repository cloning process completed!")
        self.logger.info(f"📊 Summary:")
        self.logger.info(f"  - Total repositories: {report['summary']['total_repositories']}")
        self.logger.info(f"  - Successful clones: {report['summary']['successful_clones']}")
        self.logger.info(f"  - Failed clones: {report['summary']['failed_clones']}")
        self.logger.info(f"  - Success rate: {report['summary']['success_rate']}")
        self.logger.info(f"  - Total size: {report['summary']['total_size_mb']} MB ({report['summary']['total_size_gb']} GB)")
        
        self.logger.info("\n📁 Categories:")
        for category, data in report['categories'].items():
            self.logger.info(f"  - {category.title().replace('-', ' ')}: {data['count']} repos ({data['total_size_mb']} MB)")
        
        return report

if __name__ == "__main__":
    cloner = ComprehensiveRepoCloner()
    report = cloner.run_comprehensive_clone_process()
