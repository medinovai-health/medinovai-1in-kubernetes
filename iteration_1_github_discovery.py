#!/usr/bin/env python3
"""
ITERATION 1: GitHub Repository Discovery and Analysis
Discovers ALL MedinovAI repositories on GitHub.com and performs initial analysis
"""

import requests
import json
import time
import logging
import os
from typing import Dict, List, Any
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Iteration1GitHubDiscovery:
    def __init__(self):
        self.github_api_base = "https://api.github.com"
        self.discovered_repos = []
        
        # Comprehensive search strategy
        self.search_queries = [
            "medinovai",
            "myonsite healthcare",
            "AutoBidPro",
            "AutoMarketingPro", 
            "AutoSalesPro",
            "PersonalAssistant",
            "ResearchSuite",
            "QualityManagement",
            "Credentialing",
            "DataOfficer",
            "HealthLLM",
            "manus consolidation",
            "compliance healthcare",
            "clinical decision support",
            "patient portal",
            "telemedicine platform",
            "healthcare AI",
            "medical analytics"
        ]

    def search_repositories_comprehensive(self, query: str) -> List[Dict[str, Any]]:
        """Comprehensive GitHub repository search"""
        logger.info(f"🔍 Searching GitHub for: '{query}'")
        
        try:
            url = f"{self.github_api_base}/search/repositories"
            params = {
                "q": query,
                "sort": "updated",
                "order": "desc",
                "per_page": 100
            }
            
            response = requests.get(url, params=params, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                total_count = data.get("total_count", 0)
                repos = data.get("items", [])
                
                logger.info(f"📦 Found {len(repos)} repositories (total: {total_count})")
                
                # Filter for relevant repositories
                relevant_repos = []
                for repo in repos:
                    if self.is_medinovai_related(repo):
                        relevant_repos.append(self.extract_repo_info(repo, query))
                
                logger.info(f"✅ {len(relevant_repos)} relevant MedinovAI repositories found")
                return relevant_repos
                
            elif response.status_code == 403:
                logger.warning(f"⚠️  Rate limited for query: {query}")
                time.sleep(60)
                return []
            else:
                logger.error(f"❌ GitHub API error for '{query}': {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"❌ Exception searching for '{query}': {e}")
            return []

    def is_medinovai_related(self, repo: Dict[str, Any]) -> bool:
        """Determine if repository is MedinovAI related"""
        
        name = repo.get("name", "").lower()
        description = repo.get("description", "").lower() if repo.get("description") else ""
        owner = repo.get("owner", {}).get("login", "").lower()
        topics = [topic.lower() for topic in repo.get("topics", [])]
        
        # Primary indicators
        primary_keywords = [
            "medinovai", "myonsite", "healthcare", "medical", "clinical"
        ]
        
        # Secondary indicators
        secondary_keywords = [
            "auto", "bid", "marketing", "sales", "subscription",
            "personal", "assistant", "research", "suite", "quality",
            "credentialing", "data", "officer", "health", "llm",
            "manus", "compliance", "audit", "patient", "provider"
        ]
        
        # Check primary indicators
        has_primary = any(keyword in name or keyword in description or keyword in owner 
                         for keyword in primary_keywords)
        
        # Check secondary indicators
        has_secondary = any(keyword in name or keyword in description 
                           for keyword in secondary_keywords)
        
        # Check topics
        has_relevant_topics = any(keyword in " ".join(topics) 
                                 for keyword in primary_keywords + secondary_keywords)
        
        return has_primary or (has_secondary and (owner in ["myonsite", "medinovai"] or has_relevant_topics))

    def extract_repo_info(self, repo: Dict[str, Any], search_query: str) -> Dict[str, Any]:
        """Extract relevant repository information"""
        
        return {
            "name": repo.get("name"),
            "full_name": repo.get("full_name"),
            "url": repo.get("html_url"),
            "clone_url": repo.get("clone_url"),
            "ssh_url": repo.get("ssh_url"),
            "description": repo.get("description"),
            "language": repo.get("language"),
            "size": repo.get("size"),
            "stargazers_count": repo.get("stargazers_count", 0),
            "watchers_count": repo.get("watchers_count", 0),
            "forks_count": repo.get("forks_count", 0),
            "open_issues_count": repo.get("open_issues_count", 0),
            "created_at": repo.get("created_at"),
            "updated_at": repo.get("updated_at"),
            "pushed_at": repo.get("pushed_at"),
            "owner": repo.get("owner", {}).get("login"),
            "owner_type": repo.get("owner", {}).get("type"),
            "private": repo.get("private", False),
            "archived": repo.get("archived", False),
            "disabled": repo.get("disabled", False),
            "topics": repo.get("topics", []),
            "license": repo.get("license", {}).get("name") if repo.get("license") else None,
            "default_branch": repo.get("default_branch"),
            "search_query": search_query,
            "discovered_at": datetime.now().isoformat()
        }

    def categorize_repository(self, repo: Dict[str, Any]) -> str:
        """Categorize repository by function"""
        
        name = repo.get("name", "").lower()
        description = repo.get("description", "").lower()
        
        # Core infrastructure
        if any(keyword in name for keyword in ["infrastructure", "core", "platform", "deployment"]):
            return "core_infrastructure"
        
        # Security and compliance
        elif any(keyword in name for keyword in ["security", "auth", "compliance", "audit", "encryption"]):
            return "security_compliance"
        
        # Data services
        elif any(keyword in name for keyword in ["data", "database", "analytics", "officer", "etl"]):
            return "data_services"
        
        # AI/ML services
        elif any(keyword in name for keyword in ["ai", "ml", "llm", "chatbot", "model", "health"]):
            return "ai_ml_services"
        
        # Business applications
        elif any(keyword in name for keyword in ["auto", "bid", "marketing", "sales", "subscription", "crm"]):
            return "business_applications"
        
        # Healthcare services
        elif any(keyword in name for keyword in ["clinical", "patient", "provider", "medical", "fhir", "hl7"]):
            return "healthcare_services"
        
        # Mobile and desktop
        elif any(keyword in name for keyword in ["ios", "android", "mobile", "desktop", "app"]):
            return "mobile_desktop"
        
        # Development tools
        elif any(keyword in name for keyword in ["developer", "dev", "tool", "test", "framework", "kit"]):
            return "development_tools"
        
        # Research and analytics
        elif any(keyword in name for keyword in ["research", "suite", "assistant", "quality", "analytics"]):
            return "research_analytics"
        
        # Legacy and others
        else:
            return "legacy_others"

    def run_iteration_1_discovery(self) -> Dict[str, Any]:
        """Execute complete Iteration 1 discovery"""
        
        logger.info("🚀 ITERATION 1: Starting comprehensive GitHub repository discovery")
        logger.info("=" * 80)
        
        all_repos = []
        
        # Search with all queries
        for query in self.search_queries:
            repos = self.search_repositories_comprehensive(query)
            all_repos.extend(repos)
            time.sleep(2)  # Rate limiting courtesy
        
        # Deduplicate by full_name
        unique_repos = {}
        for repo in all_repos:
            full_name = repo.get("full_name", "")
            if full_name and full_name not in unique_repos:
                unique_repos[full_name] = repo
        
        final_repos = list(unique_repos.values())
        
        # Filter active repositories
        active_repos = [
            repo for repo in final_repos 
            if not repo.get("archived", False) and not repo.get("disabled", False)
        ]
        
        # Categorize repositories
        categorized_repos = {}
        for repo in active_repos:
            category = self.categorize_repository(repo)
            if category not in categorized_repos:
                categorized_repos[category] = []
            categorized_repos[category].append(repo)
        
        # Generate comprehensive report
        report = {
            "iteration": 1,
            "discovery_timestamp": datetime.now().isoformat(),
            "search_queries_used": len(self.search_queries),
            "total_repositories_found": len(final_repos),
            "active_repositories": len(active_repos),
            "archived_repositories": len(final_repos) - len(active_repos),
            "categories": {
                category: len(repos) for category, repos in categorized_repos.items()
            },
            "categorized_repositories": categorized_repos,
            "all_repositories": active_repos,
            "language_distribution": self.calculate_language_distribution(active_repos),
            "owner_distribution": self.calculate_owner_distribution(active_repos),
            "size_statistics": self.calculate_size_statistics(active_repos)
        }
        
        # Save results
        self.save_iteration_1_results(report)
        
        # Log summary
        self.log_iteration_1_summary(report)
        
        return report

    def calculate_language_distribution(self, repos: List[Dict[str, Any]]) -> Dict[str, int]:
        """Calculate programming language distribution"""
        lang_dist = {}
        for repo in repos:
            lang = repo.get("language") or "Unknown"
            lang_dist[lang] = lang_dist.get(lang, 0) + 1
        return dict(sorted(lang_dist.items(), key=lambda x: x[1], reverse=True))

    def calculate_owner_distribution(self, repos: List[Dict[str, Any]]) -> Dict[str, int]:
        """Calculate repository owner distribution"""
        owner_dist = {}
        for repo in repos:
            owner = repo.get("owner", "Unknown")
            owner_dist[owner] = owner_dist.get(owner, 0) + 1
        return dict(sorted(owner_dist.items(), key=lambda x: x[1], reverse=True))

    def calculate_size_statistics(self, repos: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate repository size statistics"""
        sizes = [repo.get("size", 0) for repo in repos]
        return {
            "total_size_kb": sum(sizes),
            "average_size_kb": sum(sizes) / len(sizes) if sizes else 0,
            "largest_repo": max(repos, key=lambda x: x.get("size", 0)) if repos else None,
            "smallest_repo": min(repos, key=lambda x: x.get("size", 0)) if repos else None
        }

    def save_iteration_1_results(self, report: Dict[str, Any]):
        """Save Iteration 1 results"""
        
        # Create iteration results directory
        os.makedirs("iteration_results", exist_ok=True)
        
        # Save complete report
        with open("iteration_results/iteration_1_github_discovery.json", "w") as f:
            json.dump(report, f, indent=2)
        
        # Save repository list for cloning
        clone_list = []
        for repo in report["all_repositories"]:
            clone_list.append({
                "name": repo["name"],
                "full_name": repo["full_name"],
                "clone_url": repo["clone_url"],
                "category": self.categorize_repository(repo),
                "priority": self.calculate_priority(repo)
            })
        
        with open("iteration_results/repositories_to_analyze.json", "w") as f:
            json.dump(clone_list, f, indent=2)
        
        # Save categorized repositories
        for category, repos in report["categorized_repositories"].items():
            if repos:
                with open(f"iteration_results/category_{category}.json", "w") as f:
                    json.dump(repos, f, indent=2)
        
        logger.info("💾 Iteration 1 results saved to iteration_results/ directory")

    def calculate_priority(self, repo: Dict[str, Any]) -> int:
        """Calculate analysis priority for repository"""
        
        priority = 5  # Default priority
        
        name = repo.get("name", "").lower()
        size = repo.get("size", 0)
        updated = repo.get("updated_at", "")
        
        # High priority repositories
        if any(keyword in name for keyword in ["core", "platform", "infrastructure", "data-services"]):
            priority = 1
        elif any(keyword in name for keyword in ["security", "auth", "compliance"]):
            priority = 2
        elif any(keyword in name for keyword in ["clinical", "patient", "healthcare"]):
            priority = 2
        elif any(keyword in name for keyword in ["ai", "llm", "chatbot"]):
            priority = 3
        elif any(keyword in name for keyword in ["auto", "marketing", "sales", "bid"]):
            priority = 3
        
        # Adjust based on size (larger repos get higher priority)
        if size > 100000:  # >100MB
            priority = max(1, priority - 1)
        elif size > 10000:  # >10MB
            priority = max(2, priority - 1)
        
        return priority

    def log_iteration_1_summary(self, report: Dict[str, Any]):
        """Log comprehensive summary of Iteration 1"""
        
        logger.info("=" * 80)
        logger.info("📊 ITERATION 1 DISCOVERY SUMMARY")
        logger.info("=" * 80)
        logger.info(f"Search Queries Used: {report['search_queries_used']}")
        logger.info(f"Total Repositories Found: {report['total_repositories_found']}")
        logger.info(f"Active Repositories: {report['active_repositories']}")
        logger.info(f"Archived Repositories: {report['archived_repositories']}")
        logger.info("")
        
        logger.info("📋 Repository Categories:")
        for category, count in report['categories'].items():
            logger.info(f"  {category}: {count} repositories")
        logger.info("")
        
        logger.info("🌐 Top Languages:")
        for lang, count in list(report['language_distribution'].items())[:10]:
            logger.info(f"  {lang}: {count} repositories")
        logger.info("")
        
        logger.info("👥 Repository Owners:")
        for owner, count in list(report['owner_distribution'].items())[:10]:
            logger.info(f"  {owner}: {count} repositories")
        logger.info("")
        
        logger.info(f"💾 Total Size: {report['size_statistics']['total_size_kb']:,} KB")
        logger.info(f"📈 Average Size: {report['size_statistics']['average_size_kb']:.1f} KB")
        logger.info("=" * 80)

if __name__ == "__main__":
    discovery = Iteration1GitHubDiscovery()
    report = discovery.run_iteration_1_discovery()
    
    print(f"\n🎯 ITERATION 1 COMPLETE:")
    print(f"GitHub Repositories Discovered: {report['active_repositories']}")
    print(f"Categories Identified: {len(report['categories'])}")
    print(f"Ready for Iteration 2: Deep data structure analysis")
    print(f"\n📄 Results saved to: iteration_results/ directory")

