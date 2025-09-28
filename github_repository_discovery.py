#!/usr/bin/env python3
"""
GitHub Repository Discovery for MedinovAI Ecosystem
Discovers ALL MedinovAI repositories on GitHub.com across all organizations
"""

import requests
import json
import time
import logging
from typing import Dict, List, Any
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GitHubRepositoryDiscovery:
    def __init__(self):
        self.github_api_base = "https://api.github.com"
        self.discovered_repos = []
        self.organizations = [
            "myonsite-healthcare",
            "Myonsite", 
            "medinovai",
            "MedinovAI",
            "medinovai-org"
        ]
        self.search_terms = [
            "medinovai",
            "AutoBidPro", 
            "AutoMarketingPro",
            "AutoSalesPro",
            "PersonalAssistant",
            "ResearchSuite",
            "QualityManagement",
            "Credentialing",
            "DataOfficer",
            "HealthLLM",
            "manus",
            "compliance"
        ]

    def search_github_repositories(self, search_term: str) -> List[Dict[str, Any]]:
        """Search GitHub for repositories matching search term"""
        logger.info(f"🔍 Searching GitHub for: {search_term}")
        
        try:
            # GitHub Search API
            url = f"{self.github_api_base}/search/repositories"
            params = {
                "q": f"{search_term} in:name,description,readme",
                "sort": "updated",
                "order": "desc",
                "per_page": 100
            }
            
            response = requests.get(url, params=params, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                repos = data.get("items", [])
                
                # Filter for MedinovAI-related repositories
                medinovai_repos = []
                for repo in repos:
                    repo_name = repo.get("name", "").lower()
                    repo_desc = repo.get("description", "").lower()
                    owner = repo.get("owner", {}).get("login", "").lower()
                    
                    # Check if it's MedinovAI related
                    if any(keyword in repo_name or keyword in repo_desc or keyword in owner 
                           for keyword in ["medinovai", "myonsite", "healthcare", "auto", "manus"]):
                        
                        medinovai_repos.append({
                            "name": repo.get("name"),
                            "full_name": repo.get("full_name"),
                            "url": repo.get("html_url"),
                            "clone_url": repo.get("clone_url"),
                            "description": repo.get("description"),
                            "language": repo.get("language"),
                            "size": repo.get("size"),
                            "updated_at": repo.get("updated_at"),
                            "owner": repo.get("owner", {}).get("login"),
                            "private": repo.get("private", False),
                            "archived": repo.get("archived", False),
                            "disabled": repo.get("disabled", False),
                            "topics": repo.get("topics", []),
                            "search_term": search_term
                        })
                
                logger.info(f"📦 Found {len(medinovai_repos)} MedinovAI repositories for '{search_term}'")
                return medinovai_repos
                
            elif response.status_code == 403:
                logger.warning(f"⚠️  Rate limited for search term: {search_term}")
                time.sleep(60)  # Wait for rate limit reset
                return []
            else:
                logger.error(f"❌ GitHub API error for '{search_term}': {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"❌ Exception searching for '{search_term}': {e}")
            return []

    def run_complete_discovery(self) -> Dict[str, Any]:
        """Run complete GitHub repository discovery"""
        
        logger.info("🚀 Starting comprehensive GitHub repository discovery...")
        
        # Discover all repositories
        repositories = self.discover_all_github_repositories()
        
        # Generate comprehensive report
        report = self.generate_comprehensive_report(repositories)
        
        # Save results
        self.save_discovery_results(report)
        
        return report

if __name__ == "__main__":
    discovery = GitHubRepositoryDiscovery()
    report = discovery.run_complete_discovery()
    
    print(f"\n🎯 GITHUB DISCOVERY COMPLETE:")
    print(f"Total Repositories: {report['total_repositories']}")
    print(f"Categories Found: {len([c for c, repos in report['categories'].items() if repos])}")
    print(f"Public Repositories: {report['discovery_summary']['public_repositories']}")