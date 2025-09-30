#!/usr/bin/env python3
"""
MedinovAI Deployment Readiness Assessment
Quick assessment of repository deployment readiness
"""

import os
import json
from pathlib import Path

def assess_repository_readiness():
    """Quick assessment of MedinovAI repositories"""
    base_path = Path("/Users/dev1/github")
    results = {
        'total_repositories': 0,
        'ready_repositories': 0,
        'not_ready_repositories': 0,
        'repositories': [],
        'empty_repositories': []
    }
    
    print("🔍 Assessing MedinovAI repository deployment readiness...")
    
    # Find all MedinovAI repositories
    medinovai_repos = list(base_path.glob("*medinovai*"))
    results['total_repositories'] = len(medinovai_repos)
    
    print(f"📊 Found {len(medinovai_repos)} MedinovAI repositories")
    
    for repo_path in medinovai_repos:
        if repo_path.is_dir():
            repo_name = repo_path.name
            
            # Check for code files
            code_files = list(repo_path.glob("**/*.py")) + \
                        list(repo_path.glob("**/*.js")) + \
                        list(repo_path.glob("**/*.ts")) + \
                        list(repo_path.glob("**/*.go"))
            
            # Check for deployment files
            has_dockerfile = (repo_path / "Dockerfile").exists()
            has_k8s = any((repo_path / k8s_dir).exists() for k8s_dir in ["k8s", "deploy", "kubernetes"])
            has_requirements = any((repo_path / req_file).exists() for req_file in ["requirements.txt", "package.json", "go.mod"])
            
            # Calculate readiness
            code_count = len(code_files)
            is_ready = code_count >= 5 and (has_dockerfile or has_k8s) and has_requirements
            
            repo_info = {
                'name': repo_name,
                'path': str(repo_path),
                'code_files': code_count,
                'has_dockerfile': has_dockerfile,
                'has_k8s': has_k8s,
                'has_requirements': has_requirements,
                'is_ready': is_ready
            }
            
            results['repositories'].append(repo_info)
            
            if is_ready:
                results['ready_repositories'] += 1
                print(f"✅ {repo_name} - Ready ({code_count} code files)")
            else:
                results['not_ready_repositories'] += 1
                if code_count < 5:
                    results['empty_repositories'].append(repo_name)
                    print(f"❌ {repo_name} - Empty/Incomplete ({code_count} code files)")
                else:
                    print(f"⚠️  {repo_name} - Missing deployment config ({code_count} code files)")
    
    # Generate summary
    readiness_percentage = (results['ready_repositories'] / results['total_repositories']) * 100 if results['total_repositories'] > 0 else 0
    
    print(f"\n📊 DEPLOYMENT READINESS SUMMARY:")
    print(f"   Total Repositories: {results['total_repositories']}")
    print(f"   Ready for Deployment: {results['ready_repositories']} ({readiness_percentage:.1f}%)")
    print(f"   Not Ready: {results['not_ready_repositories']}")
    print(f"   Empty Repositories: {len(results['empty_repositories'])}")
    
    if results['empty_repositories']:
        print(f"\n🏗️  EMPTY REPOSITORIES NEEDING PLACEHOLDER CODE:")
        for repo in results['empty_repositories']:
            print(f"   - {repo}")
    
    # Save results
    with open("deployment_readiness_results.json", "w") as f:
        json.dump(results, f, indent=2)
    
    print(f"\n💾 Results saved to: deployment_readiness_results.json")
    
    return results

if __name__ == "__main__":
    results = assess_repository_readiness()


