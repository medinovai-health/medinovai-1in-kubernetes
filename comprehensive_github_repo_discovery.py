#!/usr/bin/env python3
"""
Comprehensive GitHub Repository Discovery for MedinovAI
This script discovers ALL MedinovAI repositories from GitHub using multiple search strategies
"""

import requests
import json
import time
import os
from typing import List, Dict, Set
import logging

class ComprehensiveGitHubRepoDiscovery:
    def __init__(self):
        self.logger = self._setup_logger()
        self.session = requests.Session()
        self.session.headers.update({
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'MedinovAI-Infrastructure-Analysis'
        })
        self.discovered_repos: Set[str] = set()
        self.all_repos: List[Dict] = []
        
        # Known repository patterns
        self.known_patterns = [
            'medinovai-', 'MedinovAI-', 'medinovai_', 'MedinovAI_',
            'medinovai', 'MedinovAI', 'medinovaios', 'MedinovaiOS'
        ]
        
        # Known repository names from our existing list
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
            'DataOfficer', 'ComplianceManus', 'manus-consolidation-platform'
        ]

    def _setup_logger(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(levelname)s:%(name)s:%(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

    def search_github_repositories(self, query: str, max_pages: int = 10) -> List[Dict]:
        """Search GitHub repositories with pagination"""
        repos = []
        page = 1
        
        while page <= max_pages:
            url = f'https://api.github.com/search/repositories?q={query}&per_page=100&page={page}'
            
            try:
                self.logger.info(f"Searching page {page} for: {query}")
                response = self.session.get(url)
                
                if response.status_code == 200:
                    data = response.json()
                    items = data.get('items', [])
                    
                    if not items:
                        break
                    
                    repos.extend(items)
                    self.logger.info(f"Found {len(items)} repositories on page {page}")
                    page += 1
                    
                    # Rate limiting
                    time.sleep(1)
                    
                elif response.status_code == 422:
                    self.logger.warning(f"Search query invalid: {query}")
                    break
                elif response.status_code == 403:
                    self.logger.warning("Rate limit exceeded, waiting...")
                    time.sleep(60)
                else:
                    self.logger.error(f"Error {response.status_code}: {response.text}")
                    break
                    
            except Exception as e:
                self.logger.error(f"Error searching {query}: {e}")
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
            self.logger.error(f"Error checking {owner}/{repo_name}: {e}")
            return None

    def discover_all_medinovai_repositories(self) -> List[Dict]:
        """Discover all MedinovAI repositories using multiple strategies"""
        self.logger.info("🔍 Starting comprehensive MedinovAI repository discovery")
        
        # Strategy 1: Search for known patterns
        search_queries = [
            'medinovai',
            'MedinovAI',
            'medinovai-',
            'MedinovAI-',
            'medinovaios',
            'MedinovaiOS',
            'user:medinovai',
            'user:MedinovAI'
        ]
        
        for query in search_queries:
            self.logger.info(f"Searching for: {query}")
            repos = self.search_github_repositories(query)
            
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
        
        # Strategy 2: Check known repository names directly
        self.logger.info("Checking known repository names...")
        potential_owners = ['medinovai', 'MedinovAI', 'myOnsite', 'dev1']
        
        for repo_name in self.known_repos:
            for owner in potential_owners:
                if f"{owner}/{repo_name}" not in [r['full_name'] for r in self.all_repos]:
                    repo_data = self.check_repository_exists(owner, repo_name)
                    if repo_data:
                        self.logger.info(f"Found: {owner}/{repo_name}")
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
        
        # Strategy 3: Search for repositories with specific keywords
        keyword_searches = [
            'healthcare AI',
            'medical AI',
            'healthcare platform',
            'medical platform',
            'healthcare analytics',
            'medical analytics'
        ]
        
        for keyword in keyword_searches:
            self.logger.info(f"Searching for keyword: {keyword}")
            repos = self.search_github_repositories(f'"{keyword}"')
            
            for repo in repos:
                # Check if it's related to MedinovAI
                if any(pattern.lower() in repo['name'].lower() or 
                      pattern.lower() in repo.get('description', '').lower() 
                      for pattern in self.known_patterns):
                    
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
                            'source': 'keyword_search'
                        })
        
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
        with open('comprehensive_github_discovery_report.json', 'w') as f:
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
        
        with open('all_github_medinovai_repos.json', 'w') as f:
            json.dump(repo_list, f, indent=2)
        
        # Save simple list for scripts
        with open('all_github_repo_names.txt', 'w') as f:
            for repo in report['repositories']:
                f.write(f"{repo['name']}\n")
        
        self.logger.info(f"✅ Saved {len(report['repositories'])} repositories to files")

    def run_discovery(self):
        """Run the complete discovery process"""
        self.logger.info("🚀 Starting comprehensive MedinovAI repository discovery")
        
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
    discovery = ComprehensiveGitHubRepoDiscovery()
    report = discovery.run_discovery()
