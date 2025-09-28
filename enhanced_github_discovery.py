#!/usr/bin/env python3
"""
Enhanced GitHub Repository Discovery for myonsite-healthcare
Uses multiple strategies to discover ALL repositories in the organization
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

class EnhancedGitHubDiscovery:
    def __init__(self):
        self.logger = self._setup_logger()
        self.org_name = "myonsite-healthcare"
        self.discovered_repos: Set[str] = set()
        self.all_repos: List[Dict] = []
        
        # Known repository patterns from existing analysis
        self.known_repo_patterns = [
            'medinovai-', 'MedinovAI-', 'medinovai_', 'MedinovAI_',
            'medinovai', 'MedinovAI', 'medinovaios', 'MedinovaiOS',
            'AutoBidPro', 'AutoMarketingPro', 'AutoSalesPro',
            'PersonalAssistant', 'ResearchSuite', 'Credentialing',
            'QualityManagement', 'DataOfficer', 'HealthLLM',
            'manus', 'compliance', 'healthcare', 'medical'
        ]
        
        # Potential repository names based on existing analysis
        self.potential_repo_names = [
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

    def _setup_logger(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

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

    def setup_github_cli_auth(self) -> bool:
        """Attempt to set up GitHub CLI authentication"""
        self.logger.info("🔐 Attempting to set up GitHub CLI authentication...")
        
        try:
            # Try to authenticate with GitHub CLI
            result = subprocess.run(['gh', 'auth', 'login', '--web'], 
                                  capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                self.logger.info("✅ GitHub CLI authentication setup successful")
                return True
            else:
                self.logger.warning(f"⚠️ GitHub CLI authentication setup failed: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            self.logger.warning("⚠️ GitHub CLI authentication setup timed out")
            return False
        except FileNotFoundError:
            self.logger.error("❌ GitHub CLI not found. Please install it first.")
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
        """Discover repositories using GitHub API"""
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

    def discover_repositories_search(self) -> List[Dict]:
        """Discover repositories using GitHub search API"""
        self.logger.info("🔍 Discovering repositories using GitHub search API...")
        
        pat_token = os.getenv('GITHUB_TOKEN')
        if not pat_token:
            return []
        
        headers = {
            'Accept': 'application/vnd.github.v3+json',
            'Authorization': f'token {pat_token}',
            'User-Agent': 'MedinovAI-Infrastructure-Analysis'
        }
        
        all_repos = []
        
        # Search queries for different patterns
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
            while page <= 10:  # Limit to 10 pages per query
                url = f'https://api.github.com/search/repositories?q={query}&per_page=100&page={page}'
                
                try:
                    response = requests.get(url, headers=headers, timeout=30)
                    
                    if response.status_code == 200:
                        data = response.json()
                        items = data.get('items', [])
                        
                        if not items:
                            break
                        
                        all_repos.extend(items)
                        self.logger.info(f"✅ Found {len(items)} repositories for query: {query}")
                        page += 1
                        time.sleep(0.5)
                        
                    elif response.status_code == 403:
                        self.logger.warning("⚠️ Rate limit exceeded, waiting...")
                        time.sleep(60)
                    else:
                        self.logger.warning(f"⚠️ Search failed for {query}: {response.status_code}")
                        break
                        
                except requests.RequestException as e:
                    self.logger.error(f"❌ Search request failed for {query}: {e}")
                    break
        
        return all_repos

    def check_repository_exists(self, repo_name: str) -> Optional[Dict]:
        """Check if a specific repository exists in the organization"""
        pat_token = os.getenv('GITHUB_TOKEN')
        if not pat_token:
            return None
        
        headers = {
            'Accept': 'application/vnd.github.v3+json',
            'Authorization': f'token {pat_token}',
            'User-Agent': 'MedinovAI-Infrastructure-Analysis'
        }
        
        url = f'https://api.github.com/repos/{self.org_name}/{repo_name}'
        
        try:
            response = requests.get(url, headers=headers, timeout=30)
            if response.status_code == 200:
                return response.json()
            else:
                return None
        except requests.RequestException as e:
            self.logger.error(f"❌ Error checking {repo_name}: {e}")
            return None

    def discover_known_repositories(self) -> List[Dict]:
        """Check for known repository names"""
        self.logger.info("🔍 Checking for known repository names...")
        
        repos = []
        for repo_name in self.potential_repo_names:
            repo_data = self.check_repository_exists(repo_name)
            if repo_data:
                self.logger.info(f"✅ Found known repository: {repo_name}")
                repos.append(repo_data)
            else:
                self.logger.debug(f"❌ Repository not found: {repo_name}")
        
        return repos

    def discover_from_local_repos(self) -> List[Dict]:
        """Discover repositories from existing local repositories"""
        self.logger.info("🔍 Discovering from existing local repositories...")
        
        # Check existing medinovai repositories in the parent directory
        parent_dir = Path("/Users/dev1/github")
        repos = []
        
        for repo_dir in parent_dir.iterdir():
            if repo_dir.is_dir() and any(pattern.lower() in repo_dir.name.lower() 
                                       for pattern in self.known_repo_patterns):
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

    def discover_all_repositories(self) -> List[Dict]:
        """Discover all repositories using multiple strategies"""
        self.logger.info("🚀 Starting comprehensive repository discovery...")
        
        all_repos = []
        
        # Strategy 1: GitHub CLI
        if self.test_github_cli_auth():
            repos = self.discover_repositories_gh_cli()
            all_repos.extend(repos)
        
        # Strategy 2: GitHub API
        repos = self.discover_repositories_api()
        all_repos.extend(repos)
        
        # Strategy 3: GitHub Search API
        repos = self.discover_repositories_search()
        all_repos.extend(repos)
        
        # Strategy 4: Check known repositories
        repos = self.discover_known_repositories()
        all_repos.extend(repos)
        
        # Strategy 5: Local discovery (fallback)
        repos = self.discover_from_local_repos()
        all_repos.extend(repos)
        
        # Remove duplicates
        unique_repos = {}
        for repo in all_repos:
            repo_name = repo.get('name', '')
            if repo_name and repo_name not in unique_repos:
                unique_repos[repo_name] = repo
        
        final_repos = list(unique_repos.values())
        
        self.logger.info(f"🎉 Discovery completed! Found {len(final_repos)} unique repositories")
        return final_repos

    def generate_discovery_report(self, repos: List[Dict]) -> Dict:
        """Generate comprehensive discovery report"""
        # Generate statistics
        languages = {}
        total_size = 0
        total_stars = 0
        
        for repo in repos:
            lang = repo.get('language', 'Unknown')
            languages[lang] = languages.get(lang, 0) + 1
            
            total_size += repo.get('size', 0)
            total_stars += repo.get('stargazers_count', 0)
        
        report = {
            "discovery_timestamp": datetime.now().isoformat(),
            "organization": self.org_name,
            "total_repositories_found": len(repos),
            "statistics": {
                "total_size_kb": total_size,
                "total_stars": total_stars,
                "average_size_kb": round(total_size / len(repos)) if repos else 0,
                "average_stars": round(total_stars / len(repos)) if repos else 0
            },
            "languages": languages,
            "repositories": repos
        }
        
        return report

    def save_discovery_results(self, report: Dict):
        """Save discovery results to files"""
        # Save full report
        with open('enhanced_github_discovery_report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save repository list for cloning
        repo_list = []
        for repo in report['repositories']:
            repo_list.append({
                'name': repo['name'],
                'clone_url': repo.get('cloneUrl', repo.get('clone_url', '')),
                'description': repo.get('description', ''),
                'language': repo.get('language', ''),
                'size': repo.get('size', 0)
            })
        
        with open('all_myonsite_healthcare_repos.json', 'w') as f:
            json.dump(repo_list, f, indent=2)
        
        # Save simple list for scripts
        with open('all_myonsite_healthcare_repo_names.txt', 'w') as f:
            for repo in report['repositories']:
                f.write(f"{repo['name']}\n")
        
        self.logger.info(f"✅ Saved {len(report['repositories'])} repositories to files")

    def run_enhanced_discovery(self):
        """Run the enhanced discovery process"""
        self.logger.info("🚀 Starting enhanced GitHub repository discovery")
        
        # Discover repositories
        repos = self.discover_all_repositories()
        
        # Generate report
        report = self.generate_discovery_report(repos)
        
        # Save results
        self.save_discovery_results(report)
        
        # Print summary
        self.logger.info(f"🎉 Enhanced discovery completed!")
        self.logger.info(f"📊 Total repositories found: {report['total_repositories_found']}")
        self.logger.info(f"📊 Total size: {report['statistics']['total_size_kb']:,} KB")
        self.logger.info(f"📊 Total stars: {report['statistics']['total_stars']:,}")
        
        self.logger.info("\nTop languages:")
        for lang, count in sorted(report['languages'].items(), key=lambda x: x[1], reverse=True)[:10]:
            self.logger.info(f"  {lang}: {count} repos")
        
        return report

if __name__ == "__main__":
    discovery = EnhancedGitHubDiscovery()
    report = discovery.run_enhanced_discovery()
