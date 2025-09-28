#!/usr/bin/env python3
"""
GitHub PAT-based Repository Discovery for MedinovAI
Uses GitHub Personal Access Token for authenticated access to discover ALL repositories
"""

import requests
import json
import time
import os
from typing import List, Dict, Set
import logging

class GitHubPATDiscovery:
    def __init__(self, pat_token: str = None):
        self.logger = self._setup_logger()
        self.pat_token = pat_token or os.getenv('GITHUB_TOKEN')
        
        if not self.pat_token:
            self.logger.error("❌ No GitHub PAT token provided. Set GITHUB_TOKEN environment variable or pass pat_token parameter")
            raise ValueError("GitHub PAT token required")
        
        self.session = requests.Session()
        self.session.headers.update({
            'Accept': 'application/vnd.github.v3+json',
            'Authorization': f'token {self.pat_token}',
            'User-Agent': 'MedinovAI-Infrastructure-Analysis'
        })
        
        self.discovered_repos: Set[str] = set()
        self.all_repos: List[Dict] = []
        
        # Known repository patterns and names
        self.known_repos = [
            'medinovai-api', 'medinovai-auth', 'medinovai-patient-service',
            'medinovai-dashboard', 'medinovai-analytics', 'medinovai-notifications',
            'medinovai-reports', 'medinovai-integrations', 'medinovai-workflows',
            'medinovai-monitoring', 'medinovai-credentialing', 'medinovai-data-services',
            'medinovai-ai-standards', 'medinovai-security', 'medinovai-subscription',
            'medinovai-Developer', 'medinovai-compliance-services', 'medinovai-devkit-infrastructure',
            'medinovai-backup-services', 'medinovai-DataOfficer', 'medinovai-healthLLM',
            'medinovai-api-gateway', 'PersonalAssistant', 'ResearchSuite', 'Credentialing',
            'QualityManagementSystem', 'AutoMarketingPro', 'AutoBidPro', 'AutoSalesPro',
            'DataOfficer', 'ComplianceManus', 'manus-consolidation-platform',
            'medinovai-infrastructure', 'medinovaios', 'MedinovaiOS'
        ]

    def _setup_logger(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(levelname)s:%(name)s:%(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

    def test_pat_access(self) -> bool:
        """Test if PAT token works"""
        try:
            response = self.session.get('https://api.github.com/user')
            if response.status_code == 200:
                user_data = response.json()
                self.logger.info(f"✅ PAT authenticated as: {user_data.get('login', 'unknown')}")
                return True
            else:
                self.logger.error(f"❌ PAT authentication failed: {response.status_code}")
                return False
        except Exception as e:
            self.logger.error(f"❌ PAT test failed: {e}")
            return False

    def search_repositories_authenticated(self, query: str, max_pages: int = 10) -> List[Dict]:
        """Search repositories with authenticated access"""
        repos = []
        page = 1
        
        while page <= max_pages:
            url = f'https://api.github.com/search/repositories?q={query}&per_page=100&page={page}'
            
            try:
                self.logger.info(f"🔍 Searching page {page} for: {query}")
                response = self.session.get(url)
                
                if response.status_code == 200:
                    data = response.json()
                    items = data.get('items', [])
                    
                    if not items:
                        break
                    
                    repos.extend(items)
                    self.logger.info(f"✅ Found {len(items)} repositories on page {page}")
                    page += 1
                    
                    # Respect rate limits
                    time.sleep(0.5)
                    
                elif response.status_code == 422:
                    self.logger.warning(f"⚠️ Search query invalid: {query}")
                    break
                elif response.status_code == 403:
                    # Check rate limit
                    rate_limit = response.headers.get('X-RateLimit-Remaining', '0')
                    if rate_limit == '0':
                        reset_time = response.headers.get('X-RateLimit-Reset', '0')
                        wait_time = int(reset_time) - int(time.time()) + 60
                        self.logger.warning(f"⏳ Rate limit exceeded, waiting {wait_time} seconds...")
                        time.sleep(wait_time)
                    else:
                        self.logger.warning("⏳ Rate limit approaching, waiting 60 seconds...")
                        time.sleep(60)
                else:
                    self.logger.error(f"❌ Error {response.status_code}: {response.text}")
                    break
                    
            except Exception as e:
                self.logger.error(f"❌ Error searching {query}: {e}")
                break
        
        return repos

    def get_user_repositories(self, username: str) -> List[Dict]:
        """Get all repositories for a specific user"""
        repos = []
        page = 1
        
        while True:
            url = f'https://api.github.com/users/{username}/repos?per_page=100&page={page}'
            
            try:
                self.logger.info(f"🔍 Getting repositories for user: {username} (page {page})")
                response = self.session.get(url)
                
                if response.status_code == 200:
                    items = response.json()
                    
                    if not items:
                        break
                    
                    repos.extend(items)
                    self.logger.info(f"✅ Found {len(items)} repositories for {username}")
                    page += 1
                    
                    time.sleep(0.5)
                    
                elif response.status_code == 404:
                    self.logger.warning(f"⚠️ User not found: {username}")
                    break
                else:
                    self.logger.error(f"❌ Error {response.status_code}: {response.text}")
                    break
                    
            except Exception as e:
                self.logger.error(f"❌ Error getting repos for {username}: {e}")
                break
        
        return repos

    def get_organization_repositories(self, org_name: str) -> List[Dict]:
        """Get all repositories for an organization"""
        repos = []
        page = 1
        
        while True:
            url = f'https://api.github.com/orgs/{org_name}/repos?per_page=100&page={page}'
            
            try:
                self.logger.info(f"🔍 Getting repositories for org: {org_name} (page {page})")
                response = self.session.get(url)
                
                if response.status_code == 200:
                    items = response.json()
                    
                    if not items:
                        break
                    
                    repos.extend(items)
                    self.logger.info(f"✅ Found {len(items)} repositories for {org_name}")
                    page += 1
                    
                    time.sleep(0.5)
                    
                elif response.status_code == 404:
                    self.logger.warning(f"⚠️ Organization not found: {org_name}")
                    break
                else:
                    self.logger.error(f"❌ Error {response.status_code}: {response.text}")
                    break
                    
            except Exception as e:
                self.logger.error(f"❌ Error getting repos for {org_name}: {e}")
                break
        
        return repos

    def check_repository_exists(self, owner: str, repo_name: str) -> Dict:
        """Check if a specific repository exists"""
        url = f'https://api.github.com/repos/{owner}/{repo_name}'
        
        try:
            response = self.session.get(url)
            if response.status_code == 200:
                return response.json()
            else:
                return None
        except Exception as e:
            self.logger.error(f"❌ Error checking {owner}/{repo_name}: {e}")
            return None

    def discover_all_medinovai_repositories(self) -> List[Dict]:
        """Discover all MedinovAI repositories using multiple strategies"""
        self.logger.info("🚀 Starting comprehensive MedinovAI repository discovery with PAT")
        
        # Test PAT access first
        if not self.test_pat_access():
            return []
        
        # Strategy 1: Search for known patterns
        search_queries = [
            'medinovai',
            'MedinovAI',
            'medinovai-',
            'MedinovAI-',
            'medinovaios',
            'MedinovaiOS',
            'healthcare AI',
            'medical AI',
            'healthcare platform',
            'medical platform'
        ]
        
        for query in search_queries:
            self.logger.info(f"🔍 Searching for: {query}")
            repos = self.search_repositories_authenticated(query)
            
            for repo in repos:
                repo_name = repo['name']
                if repo_name not in self.discovered_repos:
                    self.discovered_repos.add(repo_name)
                    self.all_repos.append({
                        'name': repo['name'],
                        'full_name': repo['full_name'],
                        'clone_url': repo['clone_url'],
                        'description': repo.get('description', ''),
                        'language': repo.get('language', ''),
                        'size': repo.get('size', 0),
                        'stars': repo.get('stargazers_count', 0),
                        'forks': repo.get('forks_count', 0),
                        'created_at': repo.get('created_at', ''),
                        'updated_at': repo.get('updated_at', ''),
                        'source': 'github_search'
                    })
        
        # Strategy 2: Check known users/organizations
        potential_owners = ['medinovai', 'MedinovAI', 'myOnsite', 'dev1', 'medinovai-infrastructure']
        
        for owner in potential_owners:
            self.logger.info(f"🔍 Checking repositories for: {owner}")
            
            # Try as organization first
            org_repos = self.get_organization_repositories(owner)
            for repo in org_repos:
                repo_name = repo['name']
                if repo_name not in self.discovered_repos:
                    self.discovered_repos.add(repo_name)
                    self.all_repos.append({
                        'name': repo['name'],
                        'full_name': repo['full_name'],
                        'clone_url': repo['clone_url'],
                        'description': repo.get('description', ''),
                        'language': repo.get('language', ''),
                        'size': repo.get('size', 0),
                        'stars': repo.get('stargazers_count', 0),
                        'forks': repo.get('forks_count', 0),
                        'created_at': repo.get('created_at', ''),
                        'updated_at': repo.get('updated_at', ''),
                        'source': f'org_{owner}'
                    })
            
            # Try as user if no org repos found
            if not org_repos:
                user_repos = self.get_user_repositories(owner)
                for repo in user_repos:
                    repo_name = repo['name']
                    if repo_name not in self.discovered_repos:
                        self.discovered_repos.add(repo_name)
                        self.all_repos.append({
                            'name': repo['name'],
                            'full_name': repo['full_name'],
                            'clone_url': repo['clone_url'],
                            'description': repo.get('description', ''),
                            'language': repo.get('language', ''),
                            'size': repo.get('size', 0),
                            'stars': repo.get('stargazers_count', 0),
                            'forks': repo.get('forks_count', 0),
                            'created_at': repo.get('created_at', ''),
                            'updated_at': repo.get('updated_at', ''),
                            'source': f'user_{owner}'
                        })
        
        # Strategy 3: Check known repository names directly
        self.logger.info("🔍 Checking known repository names...")
        for repo_name in self.known_repos:
            for owner in potential_owners:
                if f"{owner}/{repo_name}" not in [r['full_name'] for r in self.all_repos]:
                    repo_data = self.check_repository_exists(owner, repo_name)
                    if repo_data:
                        self.logger.info(f"✅ Found: {owner}/{repo_name}")
                        self.all_repos.append({
                            'name': repo_data['name'],
                            'full_name': repo_data['full_name'],
                            'clone_url': repo_data['clone_url'],
                            'description': repo_data.get('description', ''),
                            'language': repo_data.get('language', ''),
                            'size': repo_data.get('size', 0),
                            'stars': repo_data.get('stargazers_count', 0),
                            'forks': repo_data.get('forks_count', 0),
                            'created_at': repo_data.get('created_at', ''),
                            'updated_at': repo_data.get('updated_at', ''),
                            'source': 'direct_check'
                        })
                        break
        
        return self.all_repos

    def generate_comprehensive_report(self) -> Dict:
        """Generate comprehensive discovery report"""
        # Remove duplicates based on full_name
        unique_repos = {}
        for repo in self.all_repos:
            unique_repos[repo['full_name']] = repo
        
        final_repos = list(unique_repos.values())
        
        # Generate statistics
        languages = {}
        sources = {}
        total_size = 0
        total_stars = 0
        
        for repo in final_repos:
            lang = repo['language'] or 'Unknown'
            languages[lang] = languages.get(lang, 0) + 1
            
            source = repo['source']
            sources[source] = sources.get(source, 0) + 1
            
            total_size += repo['size']
            total_stars += repo['stars']
        
        report = {
            "discovery_timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "total_repositories_found": len(final_repos),
            "statistics": {
                "total_size_kb": total_size,
                "total_stars": total_stars,
                "average_size_kb": round(total_size / len(final_repos)) if final_repos else 0,
                "average_stars": round(total_stars / len(final_repos)) if final_repos else 0
            },
            "languages": languages,
            "discovery_sources": sources,
            "repositories": final_repos
        }
        
        return report

    def save_results(self, report: Dict):
        """Save discovery results to files"""
        # Save full report
        with open('comprehensive_github_pat_discovery_report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save repository list for analysis
        repo_list = []
        for repo in report['repositories']:
            repo_list.append({
                'name': repo['name'],
                'full_name': repo['full_name'],
                'clone_url': repo['clone_url'],
                'language': repo['language'],
                'size': repo['size']
            })
        
        with open('all_github_medinovai_repos_pat.json', 'w') as f:
            json.dump(repo_list, f, indent=2)
        
        # Save simple list for scripts
        with open('all_github_repo_names_pat.txt', 'w') as f:
            for repo in report['repositories']:
                f.write(f"{repo['name']}\n")
        
        self.logger.info(f"✅ Saved {len(report['repositories'])} repositories to files")

    def run_discovery(self):
        """Run the complete discovery process"""
        self.logger.info("🚀 Starting comprehensive MedinovAI repository discovery with PAT")
        
        # Discover repositories
        repos = self.discover_all_medinovai_repositories()
        
        # Generate report
        report = self.generate_comprehensive_report()
        
        # Save results
        self.save_results(report)
        
        # Print summary
        self.logger.info(f"🎉 Discovery completed!")
        self.logger.info(f"📊 Total repositories found: {report['total_repositories_found']}")
        self.logger.info(f"📊 Total size: {report['statistics']['total_size_kb']:,} KB")
        self.logger.info(f"📊 Total stars: {report['statistics']['total_stars']:,}")
        
        self.logger.info("\nTop languages:")
        for lang, count in sorted(report['languages'].items(), key=lambda x: x[1], reverse=True)[:10]:
            self.logger.info(f"  {lang}: {count} repos")
        
        self.logger.info("\nDiscovery sources:")
        for source, count in report['discovery_sources'].items():
            self.logger.info(f"  {source}: {count} repos")
        
        return report

if __name__ == "__main__":
    # You can set your PAT token here or as environment variable
    # discovery = GitHubPATDiscovery(pat_token="your_pat_token_here")
    discovery = GitHubPATDiscovery()
    report = discovery.run_discovery()
