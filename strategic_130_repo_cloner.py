#!/usr/bin/env python3
"""
Strategic 130 Repository Cloner for myonsite-healthcare
Clones ALL repositories from myonsite-healthcare organization while respecting GitHub rate limits
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
import signal
import sys

class Strategic130RepoCloner:
    def __init__(self, base_dir: str = "/Users/dev1/github/myonsite-healthcare"):
        self.logger = self._setup_logger()
        self.base_dir = Path(base_dir)
        self.org_name = "myonsite-healthcare"
        self.discovered_repos: List[Dict] = []
        self.clone_results: Dict[str, Dict] = {}
        self.lock = Lock()
        self.rate_limit_remaining = 5000
        self.rate_limit_reset = 0
        self.total_repos_expected = 130
        
        # Create base directory structure
        self._create_directory_structure()
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def _setup_logger(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

    def _signal_handler(self, signum, frame):
        """Handle graceful shutdown"""
        self.logger.info("🛑 Received shutdown signal. Saving progress...")
        self._save_progress()
        sys.exit(0)

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
            'archived',
            'backup',
            'temp'
        ]
        
        self.base_dir.mkdir(parents=True, exist_ok=True)
        for category in categories:
            (self.base_dir / category).mkdir(exist_ok=True)
        
        self.logger.info(f"✅ Created directory structure at {self.base_dir}")

    def check_rate_limit(self, response: requests.Response) -> bool:
        """Check and handle rate limiting"""
        if 'X-RateLimit-Remaining' in response.headers:
            self.rate_limit_remaining = int(response.headers['X-RateLimit-Remaining'])
            self.rate_limit_reset = int(response.headers.get('X-RateLimit-Reset', 0))
            
            if self.rate_limit_remaining < 50:
                wait_time = max(60, self.rate_limit_reset - int(time.time()) + 10)
                self.logger.warning(f"⚠️ Rate limit low ({self.rate_limit_remaining} remaining). Waiting {wait_time} seconds...")
                time.sleep(wait_time)
                return False
        
        return True

    def make_github_request(self, url: str, headers: Dict = None) -> Optional[requests.Response]:
        """Make a GitHub API request with rate limit handling"""
        if headers is None:
            headers = {
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'MedinovAI-Infrastructure-Analysis'
            }
        
        # Add PAT if available
        pat_token = os.getenv('GITHUB_TOKEN')
        if pat_token:
            headers['Authorization'] = f'token {pat_token}'
        
        max_retries = 3
        for attempt in range(max_retries):
            try:
                response = requests.get(url, headers=headers, timeout=30)
                
                if response.status_code == 200:
                    self.check_rate_limit(response)
                    return response
                elif response.status_code == 403:
                    if 'rate limit' in response.text.lower():
                        wait_time = 3600  # Wait 1 hour for rate limit reset
                        self.logger.warning(f"⚠️ Rate limit exceeded. Waiting {wait_time} seconds...")
                        time.sleep(wait_time)
                        continue
                    else:
                        self.logger.error(f"❌ Forbidden: {response.text}")
                        return None
                elif response.status_code == 404:
                    self.logger.debug(f"❌ Not found: {url}")
                    return None
                else:
                    self.logger.warning(f"⚠️ HTTP {response.status_code}: {response.text}")
                    if attempt < max_retries - 1:
                        time.sleep(2 ** attempt)  # Exponential backoff
                        continue
                    return None
                    
            except requests.RequestException as e:
                self.logger.error(f"❌ Request failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                    continue
                return None
        
        return None

    def discover_all_repositories_strategic(self) -> List[Dict]:
        """Discover all repositories using strategic approach"""
        self.logger.info("🚀 Starting strategic repository discovery for 130 repositories...")
        
        all_repos = []
        
        # Strategy 1: Organization API with pagination (most reliable)
        self.logger.info("📡 Strategy 1: Organization API with pagination")
        repos = self._discover_via_org_api()
        all_repos.extend(repos)
        
        # Strategy 2: Search API with targeted queries
        if len(all_repos) < self.total_repos_expected:
            self.logger.info("🔍 Strategy 2: Search API with targeted queries")
            repos = self._discover_via_search_api()
            all_repos.extend(repos)
        
        # Strategy 3: Known repository patterns
        if len(all_repos) < self.total_repos_expected:
            self.logger.info("📋 Strategy 3: Known repository patterns")
            repos = self._discover_via_known_patterns()
            all_repos.extend(repos)
        
        # Strategy 4: Local discovery (fallback)
        self.logger.info("💾 Strategy 4: Local discovery")
        repos = self._discover_from_local()
        all_repos.extend(repos)
        
        # Remove duplicates
        unique_repos = {}
        for repo in all_repos:
            repo_name = repo.get('name', '')
            full_name = repo.get('full_name', f"{self.org_name}/{repo_name}")
            if full_name not in unique_repos:
                unique_repos[full_name] = repo
        
        final_repos = list(unique_repos.values())
        
        self.logger.info(f"🎉 Strategic discovery completed! Found {len(final_repos)} unique repositories")
        return final_repos

    def _discover_via_org_api(self) -> List[Dict]:
        """Discover repositories using organization API with pagination"""
        self.logger.info("🔍 Discovering repositories using organization API...")
        
        repos = []
        page = 1
        per_page = 100
        
        while True:
            url = f'https://api.github.com/orgs/{self.org_name}/repos?per_page={per_page}&page={page}&sort=created&direction=desc'
            
            self.logger.info(f"📡 Fetching page {page} (up to {per_page} repos per page)...")
            response = self.make_github_request(url)
            
            if not response:
                self.logger.warning(f"⚠️ Failed to fetch page {page}")
                break
            
            page_repos = response.json()
            if not page_repos:
                self.logger.info(f"✅ No more repositories found on page {page}")
                break
            
            repos.extend(page_repos)
            self.logger.info(f"✅ Found {len(page_repos)} repositories on page {page}")
            
            # If we got fewer than per_page, we're on the last page
            if len(page_repos) < per_page:
                break
            
            page += 1
            time.sleep(2)  # Be respectful to the API
        
        self.logger.info(f"🎉 Organization API discovery complete: {len(repos)} repositories found")
        return repos

    def _discover_via_search_api(self) -> List[Dict]:
        """Discover repositories using search API with targeted queries"""
        self.logger.info("🔍 Discovering repositories using search API...")
        
        all_repos = []
        
        # Targeted search queries
        search_queries = [
            f'org:{self.org_name}',
            f'org:{self.org_name} medinovai',
            f'org:{self.org_name} MedinovAI',
            f'org:{self.org_name} healthcare',
            f'org:{self.org_name} medical',
            f'org:{self.org_name} AI',
            f'org:{self.org_name} platform'
        ]
        
        for query in search_queries:
            self.logger.info(f"🔍 Searching for: {query}")
            
            page = 1
            while page <= 5:  # Limit to 5 pages per query
                url = f'https://api.github.com/search/repositories?q={query}&per_page=100&page={page}&sort=created&order=desc'
                
                response = self.make_github_request(url)
                if not response:
                    break
                
                data = response.json()
                items = data.get('items', [])
                
                if not items:
                    break
                
                # Filter for our organization
                org_repos = [item for item in items if item.get('owner', {}).get('login', '').lower() == self.org_name.lower()]
                all_repos.extend(org_repos)
                
                self.logger.info(f"✅ Found {len(org_repos)} repositories for query: {query} (page {page})")
                
                # If we got fewer than 100, we're on the last page
                if len(items) < 100:
                    break
                
                page += 1
                time.sleep(3)  # Be respectful to the API
        
        self.logger.info(f"🎉 Search API discovery complete: {len(all_repos)} repositories found")
        return all_repos

    def _discover_via_known_patterns(self) -> List[Dict]:
        """Discover repositories using known patterns"""
        self.logger.info("🔍 Discovering repositories using known patterns...")
        
        # Known repository patterns
        known_patterns = [
            'medinovai-api', 'medinovai-auth', 'medinovai-patient-service',
            'medinovai-dashboard', 'medinovai-analytics', 'medinovai-notifications',
            'medinovai-reports', 'medinovai-integrations', 'medinovai-workflows',
            'medinovai-monitoring', 'medinovai-credentialing', 'medinovai-data-services',
            'medinovai-ai-standards', 'medinovai-security', 'medinovai-subscription',
            'medinovai-Developer', 'medinovai-compliance-services', 'medinovai-devkit-infrastructure',
            'medinovai-backup-services', 'medinovai-DataOfficer', 'medinovai-healthLLM',
            'medinovai-api-gateway', 'medinovai-infrastructure', 'medinovaios',
            'medinovai-clinical-services', 'medinovai-authorization', 'medinovai-audit-logging',
            'medinovai-alerting-services', 'medinovai-performance-monitoring',
            'medinovai-testing-framework', 'medinovai-ui-components', 'medinovai-integration-services',
            'medinovai-monitoring-services', 'medinovai-disaster-recovery',
            'medinovai-configuration-management', 'medinovai-core-platform',
            'medinovai-development', 'medinovai-healthcare-utilities',
            'medinovai-maads', 'medinovai-security-services', 'medinovai-registry',
            'medinovai-etmf', 'medinovai-EDC', 'medinovai-ResearchSuite',
            'PersonalAssistant', 'ResearchSuite', 'Credentialing', 'QualityManagementSystem',
            'AutoMarketingPro', 'AutoBidPro', 'AutoSalesPro', 'DataOfficer',
            'ComplianceManus', 'manus-consolidation-platform', 'subscription'
        ]
        
        repos = []
        for repo_name in known_patterns:
            url = f'https://api.github.com/repos/{self.org_name}/{repo_name}'
            response = self.make_github_request(url)
            if response and response.status_code == 200:
                repo_data = response.json()
                repos.append(repo_data)
                self.logger.info(f"✅ Found known repository: {repo_name}")
            time.sleep(0.5)  # Be respectful
        
        self.logger.info(f"🎉 Known patterns discovery complete: {len(repos)} repositories found")
        return repos

    def _discover_from_local(self) -> List[Dict]:
        """Discover repositories from existing local repositories"""
        self.logger.info("🔍 Discovering from existing local repositories...")
        
        parent_dir = Path("/Users/dev1/github")
        repos = []
        
        for repo_dir in parent_dir.iterdir():
            if repo_dir.is_dir():
                git_dir = repo_dir / '.git'
                if git_dir.exists():
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
                                'clone_url': result.stdout.strip()
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

    def backup_existing_repo(self, repo_name: str, target_dir: Path) -> bool:
        """Backup existing repository to prevent data loss"""
        if target_dir.exists():
            backup_dir = self.base_dir / 'backup' / f"{repo_name}-backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
            try:
                self.logger.info(f"💾 Backing up existing {repo_name} to {backup_dir}")
                subprocess.run(['cp', '-r', str(target_dir), str(backup_dir)], check=True)
                return True
            except subprocess.CalledProcessError as e:
                self.logger.error(f"❌ Failed to backup {repo_name}: {e}")
                return False
        return True

    def clone_repository_safe(self, repo: Dict) -> Dict:
        """Clone a single repository with safety measures"""
        repo_name = repo.get('name', '')
        category = self.categorize_repository(repo)
        target_dir = self.base_dir / category / repo_name
        clone_url = repo.get('clone_url', repo.get('cloneUrl', ''))
        
        result = {
            'name': repo_name,
            'category': category,
            'target_dir': str(target_dir),
            'clone_url': clone_url,
            'success': False,
            'error': None,
            'size': 0,
            'backed_up': False
        }
        
        try:
            # Backup existing repository if it exists
            if target_dir.exists():
                result['backed_up'] = self.backup_existing_repo(repo_name, target_dir)
                if not result['backed_up']:
                    result['error'] = "Failed to backup existing repository"
                    return result
            
            # Skip if already exists and is up to date
            if target_dir.exists() and not result['backed_up']:
                self.logger.info(f"⏭️  Skipping {repo_name} (already exists and not backed up)")
                result['success'] = True
                result['size'] = self._get_directory_size(target_dir)
                return result
            
            self.logger.info(f"📥 Cloning {repo_name} to {category}/")
            
            # Clone repository with timeout
            clone_result = subprocess.run([
                'git', 'clone', '--depth', '1', clone_url, str(target_dir)
            ], capture_output=True, text=True, timeout=600)  # 10 minute timeout
            
            if clone_result.returncode == 0:
                result['success'] = True
                result['size'] = self._get_directory_size(target_dir)
                self.logger.info(f"✅ Successfully cloned {repo_name}")
            else:
                result['error'] = clone_result.stderr
                self.logger.error(f"❌ Failed to clone {repo_name}: {clone_result.stderr}")
                
        except subprocess.TimeoutExpired:
            result['error'] = "Clone timeout (10 minutes)"
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

    def clone_repositories_batch(self, repos: List[Dict], batch_size: int = 5) -> Dict[str, Dict]:
        """Clone repositories in batches to respect rate limits"""
        self.logger.info(f"🚀 Starting batch cloning of {len(repos)} repositories (batch size: {batch_size})")
        
        total_batches = (len(repos) + batch_size - 1) // batch_size
        
        for batch_num in range(total_batches):
            start_idx = batch_num * batch_size
            end_idx = min(start_idx + batch_size, len(repos))
            batch_repos = repos[start_idx:end_idx]
            
            self.logger.info(f"📦 Processing batch {batch_num + 1}/{total_batches} ({len(batch_repos)} repositories)")
            
            with concurrent.futures.ThreadPoolExecutor(max_workers=batch_size) as executor:
                future_to_repo = {
                    executor.submit(self.clone_repository_safe, repo): repo 
                    for repo in batch_repos
                }
                
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
            
            # Save progress after each batch
            self._save_progress()
            
            # Wait between batches to be respectful to GitHub
            if batch_num < total_batches - 1:
                wait_time = 30  # 30 seconds between batches
                self.logger.info(f"⏳ Waiting {wait_time} seconds before next batch...")
                time.sleep(wait_time)
        
        return self.clone_results

    def _save_progress(self):
        """Save current progress to file"""
        progress_file = self.base_dir / 'cloning_progress.json'
        progress_data = {
            'timestamp': datetime.now().isoformat(),
            'total_repos': len(self.discovered_repos),
            'cloned_repos': len(self.clone_results),
            'successful_clones': len([r for r in self.clone_results.values() if r.get('success', False)]),
            'failed_clones': len([r for r in self.clone_results.values() if not r.get('success', False)]),
            'clone_results': self.clone_results
        }
        
        with open(progress_file, 'w') as f:
            json.dump(progress_data, f, indent=2)
        
        self.logger.info(f"💾 Progress saved: {progress_data['successful_clones']}/{progress_data['total_repos']} repositories cloned")

    def generate_final_report(self) -> Dict:
        """Generate final comprehensive report"""
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
                'total_repositories_discovered': len(self.discovered_repos),
                'total_repositories_cloned': len(self.clone_results),
                'successful_clones': len(successful),
                'failed_clones': len(failed),
                'success_rate': f"{(len(successful) / len(self.clone_results) * 100):.1f}%" if self.clone_results else "0%",
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
                            'size_mb': round(r.get('size', 0) / (1024 * 1024), 2),
                            'backed_up': r.get('backed_up', False)
                        } for r in repos
                    ]
                } for category, repos in categories.items()
            },
            'successful_repositories': [
                {
                    'name': r['name'],
                    'category': r['category'],
                    'size_mb': round(r.get('size', 0) / (1024 * 1024), 2),
                    'backed_up': r.get('backed_up', False)
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

    def save_final_report(self, report: Dict):
        """Save final report to files"""
        # Save JSON report
        report_file = self.base_dir / 'final_130_repos_clone_report.json'
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save markdown report
        md_file = self.base_dir / 'final_130_repos_clone_report.md'
        with open(md_file, 'w') as f:
            f.write(f"# Myonsite Healthcare 130 Repositories Clone Report\n\n")
            f.write(f"**Date:** {report['timestamp']}\n")
            f.write(f"**Organization:** {report['organization']}\n")
            f.write(f"**Base Directory:** {report['base_directory']}\n\n")
            
            f.write(f"## Summary\n\n")
            f.write(f"- **Total Repositories Discovered:** {report['summary']['total_repositories_discovered']}\n")
            f.write(f"- **Total Repositories Cloned:** {report['summary']['total_repositories_cloned']}\n")
            f.write(f"- **Successful Clones:** {report['summary']['successful_clones']}\n")
            f.write(f"- **Failed Clones:** {report['summary']['failed_clones']}\n")
            f.write(f"- **Success Rate:** {report['summary']['success_rate']}\n")
            f.write(f"- **Total Size:** {report['summary']['total_size_mb']} MB ({report['summary']['total_size_gb']} GB)\n\n")
            
            f.write(f"## Categories\n\n")
            for category, data in report['categories'].items():
                f.write(f"### {category.title().replace('-', ' ')} ({data['count']} repositories, {data['total_size_mb']} MB)\n")
                for repo in data['repositories']:
                    backup_status = " (backed up)" if repo['backed_up'] else ""
                    f.write(f"- **{repo['name']}** ({repo['size_mb']} MB){backup_status}\n")
                f.write("\n")
            
            if report['failed_repositories']:
                f.write(f"## Failed Clones\n\n")
                for repo in report['failed_repositories']:
                    f.write(f"- **{repo['name']}:** {repo['error']}\n")
        
        self.logger.info(f"✅ Final reports saved to {report_file} and {md_file}")

    def run_strategic_cloning(self):
        """Run the strategic cloning process"""
        self.logger.info("🚀 Starting strategic 130 repository cloning process")
        
        # Step 1: Discover all repositories
        self.discovered_repos = self.discover_all_repositories_strategic()
        if not self.discovered_repos:
            self.logger.error("❌ No repositories discovered. Cannot proceed with cloning.")
            return None
        
        self.logger.info(f"✅ Discovered {len(self.discovered_repos)} repositories")
        
        # Step 2: Clone repositories in batches
        self.clone_repositories_batch(self.discovered_repos)
        
        # Step 3: Generate and save final report
        report = self.generate_final_report()
        self.save_final_report(report)
        
        # Step 4: Print summary
        self.logger.info("🎉 Strategic repository cloning process completed!")
        self.logger.info(f"📊 Summary:")
        self.logger.info(f"  - Total repositories discovered: {report['summary']['total_repositories_discovered']}")
        self.logger.info(f"  - Total repositories cloned: {report['summary']['total_repositories_cloned']}")
        self.logger.info(f"  - Successful clones: {report['summary']['successful_clones']}")
        self.logger.info(f"  - Failed clones: {report['summary']['failed_clones']}")
        self.logger.info(f"  - Success rate: {report['summary']['success_rate']}")
        self.logger.info(f"  - Total size: {report['summary']['total_size_mb']} MB ({report['summary']['total_size_gb']} GB)")
        
        self.logger.info("\n📁 Categories:")
        for category, data in report['categories'].items():
            self.logger.info(f"  - {category.title().replace('-', ' ')}: {data['count']} repos ({data['total_size_mb']} MB)")
        
        return report

if __name__ == "__main__":
    cloner = Strategic130RepoCloner()
    report = cloner.run_strategic_cloning()
