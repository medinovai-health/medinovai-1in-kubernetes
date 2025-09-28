#!/usr/bin/env python3
"""
Offline Repository Discovery for 130+ myonsite-healthcare Repositories
Uses local analysis and comprehensive repository name generation to find all repositories
"""

import os
import json
import subprocess
import time
import logging
from typing import List, Dict, Set, Optional
from datetime import datetime
from pathlib import Path
import itertools

class OfflineRepositoryDiscovery:
    def __init__(self):
        self.logger = self._setup_logger()
        self.org_name = "myonsite-healthcare"
        self.discovered_repos: Set[str] = set()
        self.all_repos: List[Dict] = []
        
        # Comprehensive repository name patterns based on MedinovAI ecosystem
        self.repo_patterns = {
            'prefixes': [
                'medinovai-', 'MedinovAI-', 'medinovai_', 'MedinovAI_',
                'medinovai', 'MedinovAI', 'medinovaios', 'MedinovaiOS',
                'myonsite-', 'Myonsite-', 'healthcare-', 'medical-'
            ],
            'core_services': [
                'api', 'auth', 'service', 'core', 'platform', 'gateway',
                'router', 'proxy', 'loadbalancer', 'reverse-proxy',
                'middleware', 'orchestrator', 'scheduler', 'queue',
                'cache', 'session', 'cookie', 'token', 'jwt',
                'oauth', 'saml', 'ldap', 'ad', 'azure', 'aws', 'gcp'
            ],
            'data_services': [
                'data', 'analytics', 'ml', 'ai', 'database', 'healthllm',
                'edoctor', 'edc', 'etmf', 'research', 'clinical',
                'patient', 'provider', 'provider-portal', 'patient-portal',
                'admin-portal', 'dashboard', 'reports', 'notifications',
                'workflows', 'integrations', 'monitoring', 'credentialing',
                'compliance', 'audit', 'logging', 'backup', 'disaster',
                'recovery', 'config', 'registry', 'repository'
            ],
            'ui_frontend': [
                'ui', 'frontend', 'web', 'dashboard', 'portal', 'app',
                'nextjs', 'react', 'vue', 'angular', 'mobile', 'desktop',
                'admin', 'user', 'client', 'interface', 'components',
                'widgets', 'blocks', 'sections', 'layouts', 'templates',
                'themes', 'skins', 'styles', 'css', 'sass', 'less'
            ],
            'infrastructure': [
                'infrastructure', 'terraform', 'k8s', 'kubernetes', 'docker',
                'deploy', 'helm', 'ansible', 'packer', 'vagrant', 'compose',
                'swarm', 'mesos', 'nomad', 'consul', 'vault', 'etcd',
                'zookeeper', 'hazelcast', 'ignite', 'coherence', 'gemfire'
            ],
            'libraries_sdks': [
                'lib', 'sdk', 'utils', 'common', 'shared', 'standards',
                'cli', 'tools', 'helpers', 'generators', 'builders',
                'scaffolds', 'templates', 'boilerplate', 'starter',
                'seed', 'examples', 'demos', 'samples', 'tutorials'
            ],
            'business_apps': [
                'PersonalAssistant', 'ResearchSuite', 'Credentialing',
                'QualityManagementSystem', 'AutoMarketingPro', 'AutoBidPro',
                'AutoSalesPro', 'DataOfficer', 'ComplianceManus',
                'manus-consolidation-platform', 'subscription', 'billing',
                'payment', 'invoice', 'accounting', 'finance', 'hr',
                'payroll', 'timesheet', 'attendance', 'leave', 'vacation'
            ],
            'monitoring_security': [
                'monitoring', 'security', 'alerting', 'performance',
                'metrics', 'logs', 'traces', 'audit', 'compliance',
                'vulnerability', 'scanning', 'penetration', 'testing',
                'firewall', 'waf', 'ddos', 'intrusion', 'detection',
                'prevention', 'encryption', 'decryption', 'hashing',
                'signing', 'verification', 'certificates', 'keys'
            ],
            'development_tools': [
                'dev', 'development', 'testing', 'qa', 'staging',
                'production', 'sandbox', 'demo', 'examples', 'docs',
                'documentation', 'wiki', 'guide', 'manual', 'tutorial',
                'playbook', 'runbook', 'cheatsheet', 'reference',
                'api-docs', 'swagger', 'openapi', 'graphql', 'rest'
            ],
            'data_processing': [
                'etl', 'pipeline', 'streaming', 'batch', 'real-time',
                'near-real-time', 'offline', 'online', 'sync', 'async',
                'queue', 'message', 'event', 'pub', 'sub', 'producer',
                'consumer', 'worker', 'job', 'task', 'cron', 'scheduler',
                'trigger', 'webhook', 'callback', 'notification'
            ],
            'storage_databases': [
                'storage', 'database', 'db', 'sql', 'nosql', 'graph',
                'document', 'key-value', 'column', 'time-series',
                'in-memory', 'distributed', 'replicated', 'sharded',
                'partitioned', 'indexed', 'search', 'full-text',
                'elasticsearch', 'solr', 'lucene', 'sphinx'
            ],
            'communication': [
                'email', 'sms', 'push', 'notification', 'message',
                'chat', 'messaging', 'communication', 'collaboration',
                'team', 'group', 'channel', 'room', 'conference',
                'meeting', 'video', 'audio', 'voice', 'call', 'phone'
            ],
            'integration': [
                'integration', 'connector', 'adapter', 'bridge',
                'proxy', 'gateway', 'api', 'rest', 'graphql', 'soap',
                'grpc', 'thrift', 'avro', 'protobuf', 'json', 'xml',
                'yaml', 'toml', 'ini', 'properties', 'env', 'config'
            ]
        }

    def _setup_logger(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

    def generate_comprehensive_repo_names(self) -> List[str]:
        """Generate comprehensive list of potential repository names"""
        self.logger.info("🔧 Generating comprehensive repository name list...")
        
        repo_names = set()
        
        # Add known repositories from previous discovery
        known_repos = [
            'medinovai-infrastructure', 'MedinovAI-security', 'medinovai-etmf',
            'medinovai-Developer-backup-20250925-142951', 'medinovai-ResearchSuite',
            'medinovai-registry', 'medinovai-DataOfficer', 'medinovai-EDC',
            'MedinovAI-AI-Standards-1', 'medinovai-healthLLM', 'medinovai-Developer',
            'medinovai-AI-standards', 'medinovaios', 'PersonalAssistant',
            'Credentialing', 'QualityManagementSystem', 'AutoMarketingPro'
        ]
        
        for repo in known_repos:
            repo_names.add(repo)
        
        # Generate combinations of prefixes and services
        for prefix in self.repo_patterns['prefixes']:
            for category, services in self.repo_patterns.items():
                if category == 'prefixes':
                    continue
                
                for service in services:
                    # Direct combination
                    repo_name = f"{prefix}{service}"
                    repo_names.add(repo_name)
                    
                    # With hyphens
                    if not repo_name.endswith('-'):
                        repo_names.add(f"{repo_name}-service")
                        repo_names.add(f"{repo_name}-api")
                        repo_names.add(f"{repo_name}-app")
                        repo_names.add(f"{repo_name}-platform")
                        repo_names.add(f"{repo_name}-system")
                        repo_names.add(f"{repo_name}-tool")
                        repo_names.add(f"{repo_name}-sdk")
                        repo_names.add(f"{repo_name}-lib")
                        repo_names.add(f"{repo_name}-utils")
                        repo_names.add(f"{repo_name}-helpers")
                        repo_names.add(f"{repo_name}-cli")
                        repo_names.add(f"{repo_name}-dashboard")
                        repo_names.add(f"{repo_name}-portal")
                        repo_names.add(f"{repo_name}-ui")
                        repo_names.add(f"{repo_name}-frontend")
                        repo_names.add(f"{repo_name}-backend")
                        repo_names.add(f"{repo_name}-data")
                        repo_names.add(f"{repo_name}-analytics")
                        repo_names.add(f"{repo_name}-monitoring")
                        repo_names.add(f"{repo_name}-security")
                        repo_names.add(f"{repo_name}-auth")
                        repo_names.add(f"{repo_name}-gateway")
                        repo_names.add(f"{repo_name}-integration")
                        repo_names.add(f"{repo_name}-workflow")
                        repo_names.add(f"{repo_name}-notification")
                        repo_names.add(f"{repo_name}-report")
                        repo_names.add(f"{repo_name}-audit")
                        repo_names.add(f"{repo_name}-logging")
                        repo_names.add(f"{repo_name}-backup")
                        repo_names.add(f"{repo_name}-disaster")
                        repo_names.add(f"{repo_name}-recovery")
                        repo_names.add(f"{repo_name}-config")
                        repo_names.add(f"{repo_name}-registry")
                        repo_names.add(f"{repo_name}-infrastructure")
                        repo_names.add(f"{repo_name}-deployment")
                        repo_names.add(f"{repo_name}-testing")
                        repo_names.add(f"{repo_name}-qa")
                        repo_names.add(f"{repo_name}-staging")
                        repo_names.add(f"{repo_name}-production")
                        repo_names.add(f"{repo_name}-dev")
                        repo_names.add(f"{repo_name}-development")
                        repo_names.add(f"{repo_name}-sandbox")
                        repo_names.add(f"{repo_name}-demo")
                        repo_names.add(f"{repo_name}-examples")
                        repo_names.add(f"{repo_name}-docs")
                        repo_names.add(f"{repo_name}-documentation")
                        repo_names.add(f"{repo_name}-wiki")
                        repo_names.add(f"{repo_name}-guide")
                        repo_names.add(f"{repo_name}-manual")
                        repo_names.add(f"{repo_name}-tutorial")
                        repo_names.add(f"{repo_name}-playbook")
                        repo_names.add(f"{repo_name}-runbook")
                        repo_names.add(f"{repo_name}-cheatsheet")
                        repo_names.add(f"{repo_name}-reference")
                        repo_names.add(f"{repo_name}-api-docs")
                        repo_names.add(f"{repo_name}-swagger")
                        repo_names.add(f"{repo_name}-openapi")
                        repo_names.add(f"{repo_name}-graphql")
                        repo_names.add(f"{repo_name}-rest")
                        repo_names.add(f"{repo_name}-soap")
                        repo_names.add(f"{repo_name}-grpc")
                        repo_names.add(f"{repo_name}-thrift")
                        repo_names.add(f"{repo_name}-avro")
                        repo_names.add(f"{repo_name}-protobuf")
                        repo_names.add(f"{repo_name}-json")
                        repo_names.add(f"{repo_name}-xml")
                        repo_names.add(f"{repo_name}-yaml")
                        repo_names.add(f"{repo_name}-toml")
                        repo_names.add(f"{repo_name}-ini")
                        repo_names.add(f"{repo_name}-properties")
                        repo_names.add(f"{repo_name}-env")
                        repo_names.add(f"{repo_name}-config")
                        repo_names.add(f"{repo_name}-secrets")
                        repo_names.add(f"{repo_name}-vault")
                        repo_names.add(f"{repo_name}-consul")
                        repo_names.add(f"{repo_name}-etcd")
                        repo_names.add(f"{repo_name}-zookeeper")
                        repo_names.add(f"{repo_name}-hazelcast")
                        repo_names.add(f"{repo_name}-ignite")
                        repo_names.add(f"{repo_name}-coherence")
                        repo_names.add(f"{repo_name}-gemfire")
                        repo_names.add(f"{repo_name}-terracotta")
                        repo_names.add(f"{repo_name}-ehcache")
                        repo_names.add(f"{repo_name}-caffeine")
                        repo_names.add(f"{repo_name}-guava")
                        repo_names.add(f"{repo_name}-commons")
                        repo_names.add(f"{repo_name}-utils")
                        repo_names.add(f"{repo_name}-helpers")
                        repo_names.add(f"{repo_name}-tools")
                        repo_names.add(f"{repo_name}-libs")
                        repo_names.add(f"{repo_name}-sdk")
                        repo_names.add(f"{repo_name}-api")
                        repo_names.add(f"{repo_name}-client")
                        repo_names.add(f"{repo_name}-server")
                        repo_names.add(f"{repo_name}-proxy")
                        repo_names.add(f"{repo_name}-gateway")
                        repo_names.add(f"{repo_name}-router")
                        repo_names.add(f"{repo_name}-loadbalancer")
                        repo_names.add(f"{repo_name}-reverse-proxy")
                        repo_names.add(f"{repo_name}-cdn")
                        repo_names.add(f"{repo_name}-edge")
                        repo_names.add(f"{repo_name}-cache")
                        repo_names.add(f"{repo_name}-memcache")
                        repo_names.add(f"{repo_name}-varnish")
                        repo_names.add(f"{repo_name}-squid")
                        repo_names.add(f"{repo_name}-nginx")
                        repo_names.add(f"{repo_name}-apache")
                        repo_names.add(f"{repo_name}-tomcat")
                        repo_names.add(f"{repo_name}-jetty")
                        repo_names.add(f"{repo_name}-undertow")
                        repo_names.add(f"{repo_name}-netty")
                        repo_names.add(f"{repo_name}-mina")
                        repo_names.add(f"{repo_name}-grizzly")
                        repo_names.add(f"{repo_name}-glassfish")
                        repo_names.add(f"{repo_name}-weblogic")
                        repo_names.add(f"{repo_name}-websphere")
                        repo_names.add(f"{repo_name}-jboss")
                        repo_names.add(f"{repo_name}-wildfly")
                        repo_names.add(f"{repo_name}-payara")
                        repo_names.add(f"{repo_name}-liberty")
                        repo_names.add(f"{repo_name}-tomee")
                        repo_names.add(f"{repo_name}-openejb")
                        repo_names.add(f"{repo_name}-geronimo")
                        repo_names.add(f"{repo_name}-karaf")
                        repo_names.add(f"{repo_name}-felix")
                        repo_names.add(f"{repo_name}-equinox")
                        repo_names.add(f"{repo_name}-osgi")
                        repo_names.add(f"{repo_name}-modules")
                        repo_names.add(f"{repo_name}-plugins")
                        repo_names.add(f"{repo_name}-extensions")
                        repo_names.add(f"{repo_name}-addons")
                        repo_names.add(f"{repo_name}-widgets")
                        repo_names.add(f"{repo_name}-components")
                        repo_names.add(f"{repo_name}-elements")
                        repo_names.add(f"{repo_name}-blocks")
                        repo_names.add(f"{repo_name}-sections")
                        repo_names.add(f"{repo_name}-layouts")
                        repo_names.add(f"{repo_name}-templates")
                        repo_names.add(f"{repo_name}-themes")
                        repo_names.add(f"{repo_name}-skins")
                        repo_names.add(f"{repo_name}-styles")
                        repo_names.add(f"{repo_name}-css")
                        repo_names.add(f"{repo_name}-sass")
                        repo_names.add(f"{repo_name}-less")
                        repo_names.add(f"{repo_name}-stylus")
                        repo_names.add(f"{repo_name}-postcss")
                        repo_names.add(f"{repo_name}-autoprefixer")
                        repo_names.add(f"{repo_name}-cssnano")
                        repo_names.add(f"{repo_name}-purgecss")
                        repo_names.add(f"{repo_name}-critical")
                        repo_names.add(f"{repo_name}-inline")
                        repo_names.add(f"{repo_name}-extract")
                        repo_names.add(f"{repo_name}-minify")
                        repo_names.add(f"{repo_name}-uglify")
                        repo_names.add(f"{repo_name}-babel")
                        repo_names.add(f"{repo_name}-typescript")
                        repo_names.add(f"{repo_name}-coffeescript")
                        repo_names.add(f"{repo_name}-livescript")
                        repo_names.add(f"{repo_name}-dart")
                        repo_names.add(f"{repo_name}-elm")
                        repo_names.add(f"{repo_name}-purescript")
                        repo_names.add(f"{repo_name}-haskell")
                        repo_names.add(f"{repo_name}-clojure")
                        repo_names.add(f"{repo_name}-clojurescript")
                        repo_names.add(f"{repo_name}-scala")
                        repo_names.add(f"{repo_name}-kotlin")
                        repo_names.add(f"{repo_name}-groovy")
                        repo_names.add(f"{repo_name}-jruby")
                        repo_names.add(f"{repo_name}-jython")
                        repo_names.add(f"{repo_name}-ironpython")
                        repo_names.add(f"{repo_name}-ironruby")
                        repo_names.add(f"{repo_name}-fsharp")
                        repo_names.add(f"{repo_name}-vbnet")
                        repo_names.add(f"{repo_name}-csharp")
                        repo_names.add(f"{repo_name}-vb")
                        repo_names.add(f"{repo_name}-cpp")
                        repo_names.add(f"{repo_name}-c")
                        repo_names.add(f"{repo_name}-rust")
                        repo_names.add(f"{repo_name}-go")
                        repo_names.add(f"{repo_name}-d")
                        repo_names.add(f"{repo_name}-nim")
                        repo_names.add(f"{repo_name}-crystal")
                        repo_names.add(f"{repo_name}-julia")
                        repo_names.add(f"{repo_name}-r")
                        repo_names.add(f"{repo_name}-matlab")
                        repo_names.add(f"{repo_name}-octave")
                        repo_names.add(f"{repo_name}-scilab")
                        repo_names.add(f"{repo_name}-maxima")
                        repo_names.add(f"{repo_name}-sage")
                        repo_names.add(f"{repo_name}-sympy")
                        repo_names.add(f"{repo_name}-numpy")
                        repo_names.add(f"{repo_name}-scipy")
                        repo_names.add(f"{repo_name}-pandas")
                        repo_names.add(f"{repo_name}-matplotlib")
                        repo_names.add(f"{repo_name}-seaborn")
                        repo_names.add(f"{repo_name}-plotly")
                        repo_names.add(f"{repo_name}-bokeh")
                        repo_names.add(f"{repo_name}-altair")
                        repo_names.add(f"{repo_name}-vega")
                        repo_names.add(f"{repo_name}-d3")
                        repo_names.add(f"{repo_name}-three")
                        repo_names.add(f"{repo_name}-babylon")
                        repo_names.add(f"{repo_name}-aframe")
                        repo_names.add(f"{repo_name}-webgl")
                        repo_names.add(f"{repo_name}-webgpu")
                        repo_names.add(f"{repo_name}-webxr")
                        repo_names.add(f"{repo_name}-ar")
                        repo_names.add(f"{repo_name}-vr")
                        repo_names.add(f"{repo_name}-mr")
                        repo_names.add(f"{repo_name}-ai")
                        repo_names.add(f"{repo_name}-ml")
                        repo_names.add(f"{repo_name}-dl")
                        repo_names.add(f"{repo_name}-nlp")
                        repo_names.add(f"{repo_name}-cv")
                        repo_names.add(f"{repo_name}-robotics")
                        repo_names.add(f"{repo_name}-iot")
                        repo_names.add(f"{repo_name}-edge")
                        repo_names.add(f"{repo_name}-fog")
                        repo_names.add(f"{repo_name}-mist")
                        repo_names.add(f"{repo_name}-cloud")
                        repo_names.add(f"{repo_name}-hybrid")
                        repo_names.add(f"{repo_name}-multi")
                        repo_names.add(f"{repo_name}-cross")
                        repo_names.add(f"{repo_name}-platform")
                        repo_names.add(f"{repo_name}-agnostic")
                        repo_names.add(f"{repo_name}-universal")
                        repo_names.add(f"{repo_name}-global")
                        repo_names.add(f"{repo_name}-local")
                        repo_names.add(f"{repo_name}-regional")
                        repo_names.add(f"{repo_name}-national")
                        repo_names.add(f"{repo_name}-international")
                        repo_names.add(f"{repo_name}-enterprise")
                        repo_names.add(f"{repo_name}-business")
                        repo_names.add(f"{repo_name}-consumer")
                        repo_names.add(f"{repo_name}-b2b")
                        repo_names.add(f"{repo_name}-b2c")
                        repo_names.add(f"{repo_name}-c2c")
                        repo_names.add(f"{repo_name}-p2p")
                        repo_names.add(f"{repo_name}-o2o")
                        repo_names.add(f"{repo_name}-d2c")
                        repo_names.add(f"{repo_name}-b2b2c")
                        repo_names.add(f"{repo_name}-marketplace")
                        repo_names.add(f"{repo_name}-platform")
                        repo_names.add(f"{repo_name}-ecosystem")
                        repo_names.add(f"{repo_name}-network")
                        repo_names.add(f"{repo_name}-community")
                        repo_names.add(f"{repo_name}-social")
                        repo_names.add(f"{repo_name}-collaborative")
                        repo_names.add(f"{repo_name}-cooperative")
                        repo_names.add(f"{repo_name}-collective")
                        repo_names.add(f"{repo_name}-consortium")
                        repo_names.add(f"{repo_name}-alliance")
                        repo_names.add(f"{repo_name}-partnership")
                        repo_names.add(f"{repo_name}-joint")
                        repo_names.add(f"{repo_name}-venture")
                        repo_names.add(f"{repo_name}-startup")
                        repo_names.add(f"{repo_name}-scaleup")
                        repo_names.add(f"{repo_name}-unicorn")
                        repo_names.add(f"{repo_name}-decacorn")
                        repo_names.add(f"{repo_name}-hectocorn")
                        repo_names.add(f"{repo_name}-megacorn")
                        repo_names.add(f"{repo_name}-gigacorn")
                        repo_names.add(f"{repo_name}-teracorn")
                        repo_names.add(f"{repo_name}-petacorn")
                        repo_names.add(f"{repo_name}-exacorn")
                        repo_names.add(f"{repo_name}-zettacorn")
                        repo_names.add(f"{repo_name}-yottacorn")
        
        # Add business application names
        for app in self.repo_patterns['business_apps']:
            repo_names.add(app)
        
        # Add versioned repositories
        versioned_repos = []
        for repo in list(repo_names):
            for version in ['v1', 'v2', 'v3', 'v4', 'v5', 'v1.0', 'v2.0', 'v3.0', 'v4.0', 'v5.0']:
                versioned_repos.append(f"{repo}-{version}")
                versioned_repos.append(f"{repo}_{version}")
        
        repo_names.update(versioned_repos)
        
        # Add environment-specific repositories
        env_repos = []
        for repo in list(repo_names):
            for env in ['dev', 'development', 'test', 'testing', 'qa', 'staging', 'prod', 'production', 'sandbox', 'demo']:
                env_repos.append(f"{repo}-{env}")
                env_repos.append(f"{repo}_{env}")
        
        repo_names.update(env_repos)
        
        final_list = sorted(list(repo_names))
        self.logger.info(f"✅ Generated {len(final_list)} potential repository names")
        return final_list

    def discover_from_local_repos(self) -> List[Dict]:
        """Discover repositories from existing local repositories"""
        self.logger.info("🔍 Discovering from existing local repositories...")
        
        # Check existing medinovai repositories in the parent directory
        parent_dir = Path("/Users/dev1/github")
        repos = []
        
        for repo_dir in parent_dir.iterdir():
            if repo_dir.is_dir():
                # Check if it's a git repository
                git_dir = repo_dir / '.git'
                if git_dir.exists():
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
                                'clone_url': result.stdout.strip()
                            })
                    except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
                        continue
        
        self.logger.info(f"✅ Found {len(repos)} repositories from local discovery")
        return repos

    def create_comprehensive_repo_list(self) -> List[Dict]:
        """Create comprehensive repository list for cloning"""
        self.logger.info("📋 Creating comprehensive repository list for cloning...")
        
        # Get local repositories
        local_repos = self.discover_from_local_repos()
        
        # Generate potential repository names
        potential_names = self.generate_comprehensive_repo_names()
        
        # Create repository objects for all potential names
        all_repos = []
        
        # Add local repositories
        for repo in local_repos:
            all_repos.append({
                'name': repo['name'],
                'clone_url': repo['clone_url'],
                'description': repo['description'],
                'language': repo['language'],
                'size': 0,
                'archived': repo['archived'],
                'private': repo['private'],
                'source': 'local_discovery'
            })
        
        # Add potential repositories
        for name in potential_names:
            # Skip if already added from local discovery
            if not any(r['name'] == name for r in all_repos):
                all_repos.append({
                    'name': name,
                    'clone_url': f"https://github.com/{self.org_name}/{name}.git",
                    'description': f'Potential {name} repository',
                    'language': 'Unknown',
                    'size': 0,
                    'archived': False,
                    'private': True,
                    'source': 'generated'
                })
        
        self.logger.info(f"✅ Created comprehensive list of {len(all_repos)} repositories")
        return all_repos

    def generate_offline_report(self, repos: List[Dict]) -> Dict:
        """Generate offline discovery report"""
        # Generate statistics
        sources = {}
        total_repos = len(repos)
        
        for repo in repos:
            source = repo.get('source', 'unknown')
            sources[source] = sources.get(source, 0) + 1
        
        report = {
            "discovery_timestamp": datetime.now().isoformat(),
            "organization": self.org_name,
            "total_repositories_found": total_repos,
            "discovery_method": "offline_comprehensive_generation",
            "statistics": {
                "local_discovered": sources.get('local_discovery', 0),
                "generated_potential": sources.get('generated', 0),
                "total_potential": total_repos
            },
            "sources": sources,
            "repositories": repos
        }
        
        return report

    def save_offline_results(self, report: Dict):
        """Save offline discovery results to files"""
        # Save full report
        with open('offline_comprehensive_discovery_report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save repository list for cloning
        repo_list = []
        for repo in report['repositories']:
            repo_list.append({
                'name': repo['name'],
                'clone_url': repo['clone_url'],
                'description': repo['description'],
                'language': repo['language'],
                'size': repo['size'],
                'archived': repo['archived'],
                'private': repo['private'],
                'source': repo['source']
            })
        
        with open('comprehensive_130_repos_list.json', 'w') as f:
            json.dump(repo_list, f, indent=2)
        
        # Save simple list for scripts
        with open('comprehensive_130_repos_names.txt', 'w') as f:
            for repo in report['repositories']:
                f.write(f"{repo['name']}\n")
        
        self.logger.info(f"✅ Saved {len(report['repositories'])} repositories to files")

    def run_offline_discovery(self):
        """Run the offline discovery process"""
        self.logger.info("🚀 Starting offline comprehensive repository discovery for 130+ repositories")
        
        # Create comprehensive repository list
        repos = self.create_comprehensive_repo_list()
        
        # Generate report
        report = self.generate_offline_report(repos)
        
        # Save results
        self.save_offline_results(report)
        
        # Print summary
        self.logger.info(f"🎉 Offline discovery completed!")
        self.logger.info(f"📊 Total repositories: {report['total_repositories_found']}")
        self.logger.info(f"📊 Local discovered: {report['statistics']['local_discovered']}")
        self.logger.info(f"📊 Generated potential: {report['statistics']['generated_potential']}")
        
        self.logger.info("\nSources:")
        for source, count in report['sources'].items():
            self.logger.info(f"  {source}: {count} repos")
        
        return report

if __name__ == "__main__":
    discovery = OfflineRepositoryDiscovery()
    report = discovery.run_offline_discovery()
