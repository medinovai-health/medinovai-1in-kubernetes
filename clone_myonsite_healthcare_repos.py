#!/usr/bin/env python3
"""
Comprehensive Repository Discovery and Cloning Script for myonsite-healthcare
Discovers and clones ALL repositories from the myonsite-healthcare organization
"""

import os
import json
import subprocess
import requests
import time
import logging
from typing import List, Dict, Set, Optional
from datetime import datetime
from pathlib import Path
import concurrent.futures
from threading import Lock

class MyonsiteHealthcareRepoCloner:
    def __init__(self, base_dir: str = "/Users/dev1/github/myonsite-healthcare"):
        self.logger = self._setup_logger()
        self.base_dir = Path(base_dir)
        self.org_name = "myonsite-healthcare"
        self.discovered_repos: List[Dict] = []
        self.clone_results: Dict[str, Dict] = {}
        self.lock = Lock()
        
        # Create base directory structure
        self._create_directory_structure()
        
        # Authentication methods to try
        self.auth_methods = ['gh_cli', 'ssh', 'https']
        self.current_auth = None

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

    def test_github_cli_auth(self) -> bool:
        """Test GitHub CLI authentication"""
        try:
            result = subprocess.run(['gh', 'auth', 'status'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.logger.info("✅ GitHub CLI authentication available")
                return True
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        self.logger.warning("❌ GitHub CLI authentication not available")
        return False

    def test_ssh_auth(self) -> bool:
        """Test SSH authentication with GitHub"""
        try:
            result = subprocess.run(['ssh', '-T', 'git@github.com'], 
                                  capture_output=True, text=True, timeout=10)
            # SSH returns exit code 1 for successful authentication
            if result.returncode == 1 and "successfully authenticated" in result.stderr.lower():
                self.logger.info("✅ SSH authentication available")
                return True
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        self.logger.warning("❌ SSH authentication not available")
        return False

    def discover_repositories_gh_cli(self) -> List[Dict]:
        """Discover repositories using GitHub CLI"""
        self.logger.info("🔍 Discovering repositories using GitHub CLI...")
        
        try:
            # Get all repositories from the organization
            result = subprocess.run([
                'gh', 'repo', 'list', self.org_name, 
                '--limit', '1000',
                '--json', 'name,description,language,archived,private,createdAt,updatedAt,defaultBranchRef,cloneUrl'
            ], capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                repos_data = json.loads(result.stdout)
                self.logger.info(f"✅ Found {len(repos_data)} repositories via GitHub CLI")
                return repos_data
            else:
                self.logger.error(f"❌ GitHub CLI failed: {result.stderr}")
                return []
                
        except (subprocess.TimeoutExpired, json.JSONDecodeError) as e:
            self.logger.error(f"❌ GitHub CLI discovery failed: {e}")
            return []

    def discover_repositories_api(self) -> List[Dict]:
        """Discover repositories using GitHub API (requires PAT)"""
        self.logger.info("🔍 Discovering repositories using GitHub API...")
        
        # Try to get PAT from environment
        pat_token = os.getenv('GITHUB_TOKEN')
        if not pat_token:
            self.logger.warning("❌ No GITHUB_TOKEN environment variable found")
            return []
        
        headers = {
            'Accept': 'application/vnd.github.v3+json',
            'Authorization': f'token {pat_token}',
            'User-Agent': 'MedinovAI-Infrastructure-Analysis'
        }
        
        repos = []
        page = 1
        
        while True:
            url = f'https://api.github.com/orgs/{self.org_name}/repos?per_page=100&page={page}'
            
            try:
                response = requests.get(url, headers=headers, timeout=30)
                
                if response.status_code == 200:
                    page_repos = response.json()
                    if not page_repos:
                        break
                    
                    repos.extend(page_repos)
                    self.logger.info(f"✅ Found {len(page_repos)} repositories on page {page}")
                    page += 1
                    time.sleep(0.5)  # Rate limiting
                    
                elif response.status_code == 403:
                    self.logger.error("❌ GitHub API rate limit exceeded")
                    break
                else:
                    self.logger.error(f"❌ GitHub API error: {response.status_code}")
                    break
                    
            except requests.RequestException as e:
                self.logger.error(f"❌ GitHub API request failed: {e}")
                break
        
        return repos

    def discover_repositories(self) -> List[Dict]:
        """Discover repositories using available authentication methods"""
        self.logger.info("🚀 Starting repository discovery...")
        
        # Try GitHub CLI first
        if self.test_github_cli_auth():
            repos = self.discover_repositories_gh_cli()
            if repos:
                self.current_auth = 'gh_cli'
                return repos
        
        # Try GitHub API with PAT
        repos = self.discover_repositories_api()
        if repos:
            self.current_auth = 'api'
            return repos
        
        # Fallback: try to discover from existing local repos
        self.logger.warning("⚠️ No authentication available, using fallback discovery")
        return self._discover_from_local_repos()

    def _discover_from_local_repos(self) -> List[Dict]:
        """Fallback: discover repositories from existing local repositories"""
        self.logger.info("🔍 Attempting fallback discovery from local repositories...")
        
        # Check existing medinovai repositories in the parent directory
        parent_dir = Path("/Users/dev1/github")
        repos = []
        
        for repo_dir in parent_dir.iterdir():
            if repo_dir.is_dir() and 'medinovai' in repo_dir.name.lower():
                # Try to get remote URL
                try:
                    result = subprocess.run([
                        'git', 'remote', 'get-url', 'origin'
                    ], cwd=repo_dir, capture_output=True, text=True, timeout=10)
                    
                    if result.returncode == 0 and self.org_name in result.stdout:
                        repos.append({
                            'name': repo_dir.name,
                            'description': 'Discovered from local repository',
                            'language': 'Unknown',
                            'archived': False,
                            'private': True,
                            'cloneUrl': result.stdout.strip()
                        })
                except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
                    continue
        
        self.logger.info(f"✅ Found {len(repos)} repositories from local discovery")
        return repos

    def categorize_repository(self, repo: Dict) -> str:
        """Categorize repository based on name and description"""
        name = repo.get('name', '').lower()
        description = repo.get('description', '').lower()
        
        # Core services
        if any(keyword in name for keyword in ['api', 'auth', 'service', 'core', 'platform']):
            return 'core-services'
        
        # Data services
        if any(keyword in name for keyword in ['data', 'analytics', 'ml', 'ai', 'database']):
            return 'data-services'
        
        # UI/Frontend
        if any(keyword in name for keyword in ['ui', 'frontend', 'web', 'dashboard', 'portal', 'app']):
            return 'ui-frontend'
        
        # Infrastructure
        if any(keyword in name for keyword in ['infrastructure', 'terraform', 'k8s', 'kubernetes', 'docker', 'deploy']):
            return 'infrastructure'
        
        # Libraries/SDKs
        if any(keyword in name for keyword in ['lib', 'sdk', 'utils', 'common', 'shared']):
            return 'libraries-sdks'
        
        # Documentation
        if any(keyword in name for keyword in ['doc', 'wiki', 'guide', 'manual']):
            return 'documentation'
        
        # Tools/Utilities
        if any(keyword in name for keyword in ['tool', 'script', 'util', 'helper']):
            return 'tools-utilities'
        
        # Default to core-services
        return 'core-services'

    def get_clone_url(self, repo: Dict) -> str:
        """Get appropriate clone URL based on authentication method"""
        if self.current_auth == 'ssh' or self.test_ssh_auth():
            # Convert HTTPS URL to SSH
            clone_url = repo.get('cloneUrl', '')
            if 'https://github.com/' in clone_url:
                return clone_url.replace('https://github.com/', 'git@github.com:')
            return clone_url
        else:
            # Use HTTPS URL
            return repo.get('cloneUrl', '')

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

    def generate_clone_report(self) -> Dict:
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
            'authentication_method': self.current_auth,
            'summary': {
                'total_repositories': len(self.discovered_repos),
                'successful_clones': len(successful),
                'failed_clones': len(failed),
                'success_rate': f"{(len(successful) / len(self.discovered_repos) * 100):.1f}%" if self.discovered_repos else "0%",
                'total_size_bytes': total_size,
                'total_size_mb': round(total_size / (1024 * 1024), 2)
            },
            'categories': {
                category: {
                    'count': len(repos),
                    'repositories': [r['name'] for r in repos]
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

    def save_report(self, report: Dict):
        """Save cloning report to files"""
        # Save JSON report
        report_file = self.base_dir / 'clone_report.json'
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save markdown report
        md_file = self.base_dir / 'clone_report.md'
        with open(md_file, 'w') as f:
            f.write(f"# Myonsite Healthcare Repository Clone Report\n\n")
            f.write(f"**Date:** {report['timestamp']}\n")
            f.write(f"**Organization:** {report['organization']}\n")
            f.write(f"**Base Directory:** {report['base_directory']}\n")
            f.write(f"**Authentication:** {report['authentication_method']}\n\n")
            
            f.write(f"## Summary\n\n")
            f.write(f"- **Total Repositories:** {report['summary']['total_repositories']}\n")
            f.write(f"- **Successful Clones:** {report['summary']['successful_clones']}\n")
            f.write(f"- **Failed Clones:** {report['summary']['failed_clones']}\n")
            f.write(f"- **Success Rate:** {report['summary']['success_rate']}\n")
            f.write(f"- **Total Size:** {report['summary']['total_size_mb']} MB\n\n")
            
            f.write(f"## Categories\n\n")
            for category, data in report['categories'].items():
                f.write(f"### {category.title()} ({data['count']} repositories)\n")
                for repo in data['repositories']:
                    f.write(f"- {repo}\n")
                f.write("\n")
            
            if report['failed_repositories']:
                f.write(f"## Failed Clones\n\n")
                for repo in report['failed_repositories']:
                    f.write(f"- **{repo['name']}:** {repo['error']}\n")
        
        self.logger.info(f"✅ Reports saved to {report_file} and {md_file}")

    def run_complete_clone_process(self):
        """Run the complete repository discovery and cloning process"""
        self.logger.info("🚀 Starting complete myonsite-healthcare repository cloning process")
        
        # Step 1: Discover repositories
        self.discovered_repos = self.discover_repositories()
        if not self.discovered_repos:
            self.logger.error("❌ No repositories discovered. Cannot proceed with cloning.")
            return None
        
        self.logger.info(f"✅ Discovered {len(self.discovered_repos)} repositories")
        
        # Step 2: Clone repositories
        self.clone_repositories_parallel(self.discovered_repos)
        
        # Step 3: Generate and save report
        report = self.generate_clone_report()
        self.save_report(report)
        
        # Step 4: Print summary
        self.logger.info("🎉 Repository cloning process completed!")
        self.logger.info(f"📊 Summary:")
        self.logger.info(f"  - Total repositories: {report['summary']['total_repositories']}")
        self.logger.info(f"  - Successful clones: {report['summary']['successful_clones']}")
        self.logger.info(f"  - Failed clones: {report['summary']['failed_clones']}")
        self.logger.info(f"  - Success rate: {report['summary']['success_rate']}")
        self.logger.info(f"  - Total size: {report['summary']['total_size_mb']} MB")
        
        return report

if __name__ == "__main__":
    cloner = MyonsiteHealthcareRepoCloner()
    report = cloner.run_complete_clone_process()
