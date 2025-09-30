#!/usr/bin/env python3
"""
Comprehensive MedinovAI Repository Discovery Script
Discovers all 100+ repositories across multiple sources and organizations
"""

import os
import json
import subprocess
import requests
import logging
from typing import List, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)

class MedinovAIRepositoryDiscovery:
    def __init__(self):
        self.discovered_repos = []
        self.github_orgs = [
            "myonsite-healthcare",
            "Myonsite", 
            "medinovai",
            "MedinovAI"
        ]
        
    def discover_github_repositories(self) -> List[Dict[str, Any]]:
        """Discover repositories from GitHub organizations"""
        logger.info("🔍 Discovering GitHub repositories...")
        
        github_repos = []
        
        for org in self.github_orgs:
            try:
                # Use GitHub CLI if available, otherwise use API
                result = subprocess.run(
                    ["gh", "repo", "list", org, "--json", "name,url,description,updatedAt,primaryLanguage"],
                    capture_output=True, text=True, timeout=30
                )
                
                if result.returncode == 0:
                    org_repos = json.loads(result.stdout)
                    for repo in org_repos:
                        if "medinovai" in repo["name"].lower() or any(
                            keyword in repo["name"].lower() 
                            for keyword in ["auto", "manus", "compliance", "ats", "data", "ai", "health"]
                        ):
                            github_repos.append({
                                "name": repo["name"],
                                "url": repo["url"], 
                                "source": f"github.com/{org}",
                                "description": repo.get("description", ""),
                                "last_updated": repo.get("updatedAt", ""),
                                "primary_language": repo.get("primaryLanguage", {}).get("name", "Unknown")
                            })
                            
                    logger.info(f"📦 Found {len(org_repos)} repositories in {org}")
                    
            except subprocess.TimeoutExpired:
                logger.warning(f"⏱️  Timeout discovering repositories from {org}")
            except Exception as e:
                logger.warning(f"⚠️  Failed to discover repositories from {org}: {e}")
        
        return github_repos

    def discover_local_repositories(self) -> List[Dict[str, Any]]:
        """Discover local repositories"""
        logger.info("📂 Discovering local repositories...")
        
        local_repos = []
        search_paths = [
            "/Users/dev1/github/",
            "/Users/dev1/Projects/",
            "/Users/dev1/Repositories/"
        ]
        
        for search_path in search_paths:
            if os.path.exists(search_path):
                try:
                    for item in os.listdir(search_path):
                        item_path = os.path.join(search_path, item)
                        if os.path.isdir(item_path) and ".git" in os.listdir(item_path):
                            if "medinovai" in item.lower() or any(
                                keyword in item.lower() 
                                for keyword in ["auto", "manus", "compliance", "ats", "data", "ai", "health"]
                            ):
                                local_repos.append({
                                    "name": item,
                                    "url": f"file://{item_path}",
                                    "source": "local",
                                    "path": item_path,
                                    "description": "Local repository",
                                    "primary_language": "Mixed"
                                })
                                
                except Exception as e:
                    logger.warning(f"⚠️  Failed to scan {search_path}: {e}")
        
        logger.info(f"📁 Found {len(local_repos)} local repositories")
        return local_repos

    def categorize_repositories(self, repos: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
        """Categorize repositories by type and complexity"""
        
        categories = {
            "tier_1_core_infrastructure": [],
            "tier_2_security_auth": [],
            "tier_3_data_services": [],
            "tier_4_ai_ml_services": [],
            "tier_5_business_applications": [],
            "tier_6_healthcare_services": [],
            "tier_7_mobile_desktop": [],
            "tier_8_development_tools": []
        }
        
        # Categorization rules
        for repo in repos:
            name = repo["name"].lower()
            
            if any(keyword in name for keyword in ["infrastructure", "deployment", "k8s", "docker", "core"]):
                categories["tier_1_core_infrastructure"].append(repo)
            elif any(keyword in name for keyword in ["auth", "security", "credential", "encryption", "vault"]):
                categories["tier_2_security_auth"].append(repo)
            elif any(keyword in name for keyword in ["data", "database", "etl", "pipeline", "analytics"]):
                categories["tier_3_data_services"].append(repo)
            elif any(keyword in name for keyword in ["ai", "ml", "chatbot", "model", "inference"]):
                categories["tier_4_ai_ml_services"].append(repo)
            elif any(keyword in name for keyword in ["auto", "bid", "marketing", "sales", "crm", "ats"]):
                categories["tier_5_business_applications"].append(repo)
            elif any(keyword in name for keyword in ["health", "medical", "clinical", "patient", "fhir", "hl7"]):
                categories["tier_6_healthcare_services"].append(repo)
            elif any(keyword in name for keyword in ["ios", "android", "mobile", "desktop", "electron"]):
                categories["tier_7_mobile_desktop"].append(repo)
            elif any(keyword in name for keyword in ["developer", "dev", "tool", "cli", "sdk", "test"]):
                categories["tier_8_development_tools"].append(repo)
            else:
                # Default to business applications
                categories["tier_5_business_applications"].append(repo)
        
        # Log categorization results
        for category, repos_in_category in categories.items():
            logger.info(f"📊 {category}: {len(repos_in_category)} repositories")
        
        return categories

    def run_discovery(self) -> Dict[str, Any]:
        """Run comprehensive repository discovery"""
        logger.info("🚀 Starting comprehensive MedinovAI repository discovery...")
        
        # Discover from all sources
        github_repos = self.discover_github_repositories()
        local_repos = self.discover_local_repositories()
        
        # Combine and deduplicate
        all_repos = github_repos + local_repos
        unique_repos = {}
        for repo in all_repos:
            # Use name as key for deduplication
            key = repo["name"].lower()
            if key not in unique_repos:
                unique_repos[key] = repo
        
        final_repos = list(unique_repos.values())
        
        # Categorize repositories
        categorized = self.categorize_repositories(final_repos)
        
        # Generate discovery report
        discovery_report = {
            "discovery_timestamp": datetime.now().isoformat(),
            "total_repositories_discovered": len(final_repos),
            "github_repositories": len(github_repos),
            "local_repositories": len(local_repos),
            "categories": {
                category: len(repos) for category, repos in categorized.items()
            },
            "repositories": final_repos,
            "categorized_repositories": categorized
        }
        
        # Save discovery report
        with open("comprehensive_repository_discovery.json", "w") as f:
            json.dump(discovery_report, f, indent=2)
        
        logger.info(f"📊 Discovery Complete: {len(final_repos)} repositories found")
        logger.info(f"📄 Report saved to: comprehensive_repository_discovery.json")
        
        return discovery_report

if __name__ == "__main__":
    discovery = MedinovAIRepositoryDiscovery()
    report = discovery.run_discovery()
    
    print(f"\n🎯 DISCOVERY SUMMARY:")
    print(f"Total Repositories: {report['total_repositories_discovered']}")
    print(f"GitHub Repositories: {report['github_repositories']}")
    print(f"Local Repositories: {report['local_repositories']}")
    print(f"\nCategory Breakdown:")
    for category, count in report['categories'].items():
        print(f"  {category}: {count}")

