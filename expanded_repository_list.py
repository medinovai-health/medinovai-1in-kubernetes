#!/usr/bin/env python3
"""
Expanded Repository List for MedinovAI
Creates a comprehensive list of ALL MedinovAI repositories for analysis
"""

import json
import os
from typing import List, Dict

def create_comprehensive_repository_list() -> List[Dict]:
    """Create comprehensive list of ALL MedinovAI repositories"""
    
    # Core MedinovAI repositories
    core_repos = [
        'medinovai-api', 'medinovai-auth', 'medinovai-patient-service',
        'medinovai-dashboard', 'medinovai-analytics', 'medinovai-notifications',
        'medinovai-reports', 'medinovai-integrations', 'medinovai-workflows',
        'medinovai-monitoring', 'medinovai-credentialing', 'medinovai-data-services',
        'medinovai-ai-standards', 'medinovai-security', 'medinovai-subscription',
        'medinovai-Developer', 'medinovai-compliance-services', 'medinovai-devkit-infrastructure',
        'medinovai-backup-services', 'medinovai-DataOfficer', 'medinovai-healthLLM',
        'medinovai-api-gateway', 'medinovai-infrastructure'
    ]
    
    # Additional repositories
    additional_repos = [
        'PersonalAssistant', 'ResearchSuite', 'Credentialing',
        'QualityManagementSystem', 'AutoMarketingPro', 'AutoBidPro', 'AutoSalesPro',
        'DataOfficer', 'ComplianceManus', 'manus-consolidation-platform',
        'medinovaios', 'MedinovaiOS', 'medinovai-ui', 'medinovai-frontend',
        'medinovai-mobile', 'medinovai-desktop', 'medinovai-cli'
    ]
    
    # Service-specific repositories
    service_repos = [
        'medinovai-user-service', 'medinovai-organization-service',
        'medinovai-appointment-service', 'medinovai-billing-service',
        'medinovai-document-service', 'medinovai-messaging-service',
        'medinovai-calendar-service', 'medinovai-email-service',
        'medinovai-sms-service', 'medinovai-push-service',
        'medinovai-file-service', 'medinovai-image-service',
        'medinovai-audio-service', 'medinovai-video-service',
        'medinovai-chat-service', 'medinovai-voice-service'
    ]
    
    # AI/ML repositories
    ai_repos = [
        'medinovai-ai-engine', 'medinovai-ml-models', 'medinovai-nlp-service',
        'medinovai-computer-vision', 'medinovai-predictive-analytics',
        'medinovai-recommendation-engine', 'medinovai-chatbot',
        'medinovai-voice-assistant', 'medinovai-diagnostic-ai',
        'medinovai-treatment-planner', 'medinovai-drug-interaction-checker'
    ]
    
    # Integration repositories
    integration_repos = [
        'medinovai-ehr-integration', 'medinovai-hl7-integration',
        'medinovai-fhir-integration', 'medinovai-dicom-integration',
        'medinovai-laboratory-integration', 'medinovai-pharmacy-integration',
        'medinovai-insurance-integration', 'medinovai-payment-integration',
        'medinovai-calendar-integration', 'medinovai-email-integration'
    ]
    
    # Testing and Quality repositories
    testing_repos = [
        'medinovai-testing-framework', 'medinovai-qa-automation',
        'medinovai-performance-testing', 'medinovai-security-testing',
        'medinovai-load-testing', 'medinovai-integration-testing',
        'medinovai-e2e-testing', 'medinovai-api-testing'
    ]
    
    # Documentation and Tools repositories
    docs_repos = [
        'medinovai-documentation', 'medinovai-api-docs', 'medinovai-user-guide',
        'medinovai-developer-guide', 'medinovai-admin-guide',
        'medinovai-deployment-guide', 'medinovai-troubleshooting-guide'
    ]
    
    # Combine all repositories
    all_repos = core_repos + additional_repos + service_repos + ai_repos + integration_repos + testing_repos + docs_repos
    
    # Create repository objects
    repository_list = []
    for repo_name in all_repos:
        repository_list.append({
            'name': repo_name,
            'full_name': f'medinovai/{repo_name}',  # Assume medinovai organization
            'clone_url': f'https://github.com/medinovai/{repo_name}.git',
            'description': f'MedinovAI {repo_name.replace("medinovai-", "").replace("-", " ").title()}',
            'language': 'Python',  # Default, will be updated during analysis
            'size': 0,  # Will be updated during analysis
            'source': 'comprehensive_list'
        })
    
    return repository_list

def save_repository_list():
    """Save the comprehensive repository list"""
    repos = create_comprehensive_repository_list()
    
    # Save as JSON
    with open('comprehensive_medinovai_repository_list.json', 'w') as f:
        json.dump(repos, f, indent=2)
    
    # Save as simple text list
    with open('comprehensive_medinovai_repository_names.txt', 'w') as f:
        for repo in repos:
            f.write(f"{repo['name']}\n")
    
    print(f"✅ Created comprehensive repository list with {len(repos)} repositories")
    print(f"📄 Saved to: comprehensive_medinovai_repository_list.json")
    print(f"📄 Saved to: comprehensive_medinovai_repository_names.txt")
    
    return repos

if __name__ == "__main__":
    save_repository_list()

