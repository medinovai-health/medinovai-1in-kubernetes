#!/usr/bin/env python3
"""
Comprehensive 130 Repository Finder for myonsite-healthcare
Uses multiple strategies to find ALL 130+ repositories across different organizations and users
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

class Comprehensive130RepoFinder:
    def __init__(self):
        self.logger = self._setup_logger()
        self.org_name = "myonsite-healthcare"
        self.discovered_repos: Set[str] = set()
        self.all_repos: List[Dict] = []
        
        # Multiple organizations and users to check
        self.target_orgs = [
            "myonsite-healthcare",
            "Myonsite", 
            "myonsite",
            "medinovai",
            "MedinovAI",
            "medinovai-org",
            "MedinovAI-org"
        ]
        
        # Potential users
        self.target_users = [
            "dev1",
            "myonsite",
            "medinovai",
            "MedinovAI"
        ]
        
        # Comprehensive repository name patterns
        self.repo_patterns = [
            # Core MedinovAI repositories
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
            
            # Business applications
            'PersonalAssistant', 'ResearchSuite', 'Credentialing', 'QualityManagementSystem',
            'AutoMarketingPro', 'AutoBidPro', 'AutoSalesPro', 'DataOfficer',
            'ComplianceManus', 'manus-consolidation-platform', 'subscription',
            
            # Additional potential repositories
            'medinovai-patient-portal', 'medinovai-provider-portal', 'medinovai-admin-portal',
            'medinovai-mobile-app', 'medinovai-web-app', 'medinovai-desktop-app',
            'medinovai-api-docs', 'medinovai-sdk', 'medinovai-cli',
            'medinovai-testing', 'medinovai-qa', 'medinovai-staging',
            'medinovai-production', 'medinovai-dev', 'medinovai-sandbox',
            'medinovai-demo', 'medinovai-examples', 'medinovai-templates',
            'medinovai-boilerplate', 'medinovai-starter', 'medinovai-seed',
            'medinovai-scaffold', 'medinovai-generator', 'medinovai-builder',
            'medinovai-deployer', 'medinovai-orchestrator', 'medinovai-scheduler',
            'medinovai-queue', 'medinovai-cache', 'medinovai-session',
            'medinovai-cookie', 'medinovai-token', 'medinovai-jwt',
            'medinovai-oauth', 'medinovai-saml', 'medinovai-ldap',
            'medinovai-ad', 'medinovai-azure', 'medinovai-aws',
            'medinovai-gcp', 'medinovai-k8s', 'medinovai-helm',
            'medinovai-terraform', 'medinovai-ansible', 'medinovai-packer',
            'medinovai-vagrant', 'medinovai-docker', 'medinovai-compose',
            'medinovai-swarm', 'medinovai-mesos', 'medinovai-nomad',
            'medinovai-consul', 'medinovai-vault', 'medinovai-nomad',
            'medinovai-prometheus', 'medinovai-grafana', 'medinovai-jaeger',
            'medinovai-zipkin', 'medinovai-fluentd', 'medinovai-logstash',
            'medinovai-elasticsearch', 'medinovai-kibana', 'medinovai-splunk',
            'medinovai-newrelic', 'medinovai-datadog', 'medinovai-appdynamics',
            'medinovai-sentry', 'medinovai-bugsnag', 'medinovai-rollbar',
            'medinovai-honeybadger', 'medinovai-airbrake', 'medinovai-raygun',
            'medinovai-crashlytics', 'medinovai-firebase', 'medinovai-amplitude',
            'medinovai-mixpanel', 'medinovai-segment', 'medinovai-rudder',
            'medinovai-posthog', 'medinovai-hotjar', 'medinovai-fullstory',
            'medinovai-logrocket', 'medinovai-clarity', 'medinovai-inspectlet',
            'medinovai-crazyegg', 'medinovai-optimizely', 'medinovai-vwo',
            'medinovai-unbounce', 'medinovai-mailchimp', 'medinovai-sendgrid',
            'medinovai-twilio', 'medinovai-stripe', 'medinovai-paypal',
            'medinovai-square', 'medinovai-braintree', 'medinovai-adyen',
            'medinovai-klarna', 'medinovai-affirm', 'medinovai-afterpay',
            'medinovai-shopify', 'medinovai-woocommerce', 'medinovai-magento',
            'medinovai-prestashop', 'medinovai-opencart', 'medinovai-bigcommerce',
            'medinovai-salesforce', 'medinovai-hubspot', 'medinovai-pardot',
            'medinovai-marketo', 'medinovai-eloqua', 'medinovai-act-on',
            'medinovai-mailgun', 'medinovai-mandrill', 'medinovai-postmark',
            'medinovai-ses', 'medinovai-sns', 'medinovai-sqs',
            'medinovai-s3', 'medinovai-cloudfront', 'medinovai-route53',
            'medinovai-ec2', 'medinovai-rds', 'medinovai-elasticache',
            'medinovai-redis', 'medinovai-memcached', 'medinovai-mongodb',
            'medinovai-postgresql', 'medinovai-mysql', 'medinovai-mariadb',
            'medinovai-oracle', 'medinovai-sqlserver', 'medinovai-sqlite',
            'medinovai-cassandra', 'medinovai-couchdb', 'medinovai-riak',
            'medinovai-neo4j', 'medinovai-arangodb', 'medinovai-orientdb',
            'medinovai-influxdb', 'medinovai-timescaledb', 'medinovai-clickhouse',
            'medinovai-bigquery', 'medinovai-snowflake', 'medinovai-redshift',
            'medinovai-athena', 'medinovai-glue', 'medinovai-kinesis',
            'medinovai-kafka', 'medinovai-rabbitmq', 'medinovai-activemq',
            'medinovai-zeromq', 'medinovai-nats', 'medinovai-pulsar',
            'medinovai-storm', 'medinovai-spark', 'medinovai-flink',
            'medinovai-beam', 'medinovai-samza', 'medinovai-heron',
            'medinovai-akka', 'medinovai-play', 'medinovai-lagom',
            'medinovai-spring', 'medinovai-quarkus', 'medinovai-micronaut',
            'medinovai-vertx', 'medinovai-dropwizard', 'medinovai-jersey',
            'medinovai-resteasy', 'medinovai-cxf', 'medinovai-axis',
            'medinovai-jaxws', 'medinovai-jaxrs', 'medinovai-jaxb',
            'medinovai-jpa', 'medinovai-hibernate', 'medinovai-mybatis',
            'medinovai-jdbc', 'medinovai-jooq', 'medinovai-querydsl',
            'medinovai-criteria', 'medinovai-ql', 'medinovai-jpql',
            'medinovai-hql', 'medinovai-sql', 'medinovai-nosql',
            'medinovai-graphql', 'medinovai-rest', 'medinovai-soap',
            'medinovai-grpc', 'medinovai-thrift', 'medinovai-avro',
            'medinovai-protobuf', 'medinovai-json', 'medinovai-xml',
            'medinovai-yaml', 'medinovai-toml', 'medinovai-ini',
            'medinovai-properties', 'medinovai-env', 'medinovai-config',
            'medinovai-secrets', 'medinovai-vault', 'medinovai-consul',
            'medinovai-etcd', 'medinovai-zookeeper', 'medinovai-hazelcast',
            'medinovai-ignite', 'medinovai-coherence', 'medinovai-gemfire',
            'medinovai-terracotta', 'medinovai-ehcache', 'medinovai-caffeine',
            'medinovai-guava', 'medinovai-commons', 'medinovai-utils',
            'medinovai-helpers', 'medinovai-tools', 'medinovai-libs',
            'medinovai-sdk', 'medinovai-api', 'medinovai-client',
            'medinovai-server', 'medinovai-proxy', 'medinovai-gateway',
            'medinovai-router', 'medinovai-loadbalancer', 'medinovai-reverse-proxy',
            'medinovai-cdn', 'medinovai-edge', 'medinovai-cache',
            'medinovai-memcache', 'medinovai-varnish', 'medinovai-squid',
            'medinovai-nginx', 'medinovai-apache', 'medinovai-tomcat',
            'medinovai-jetty', 'medinovai-undertow', 'medinovai-netty',
            'medinovai-mina', 'medinovai-grizzly', 'medinovai-glassfish',
            'medinovai-weblogic', 'medinovai-websphere', 'medinovai-jboss',
            'medinovai-wildfly', 'medinovai-payara', 'medinovai-liberty',
            'medinovai-tomee', 'medinovai-openejb', 'medinovai-geronimo',
            'medinovai-karaf', 'medinovai-felix', 'medinovai-equinox',
            'medinovai-osgi', 'medinovai-modules', 'medinovai-plugins',
            'medinovai-extensions', 'medinovai-addons', 'medinovai-widgets',
            'medinovai-components', 'medinovai-elements', 'medinovai-blocks',
            'medinovai-sections', 'medinovai-layouts', 'medinovai-templates',
            'medinovai-themes', 'medinovai-skins', 'medinovai-styles',
            'medinovai-css', 'medinovai-sass', 'medinovai-less',
            'medinovai-stylus', 'medinovai-postcss', 'medinovai-autoprefixer',
            'medinovai-cssnano', 'medinovai-purgecss', 'medinovai-critical',
            'medinovai-inline', 'medinovai-extract', 'medinovai-minify',
            'medinovai-uglify', 'medinovai-babel', 'medinovai-typescript',
            'medinovai-coffeescript', 'medinovai-livescript', 'medinovai-dart',
            'medinovai-elm', 'medinovai-purescript', 'medinovai-haskell',
            'medinovai-clojure', 'medinovai-clojurescript', 'medinovai-scala',
            'medinovai-kotlin', 'medinovai-groovy', 'medinovai-jruby',
            'medinovai-jython', 'medinovai-ironpython', 'medinovai-ironruby',
            'medinovai-fsharp', 'medinovai-vbnet', 'medinovai-csharp',
            'medinovai-vb', 'medinovai-cpp', 'medinovai-c',
            'medinovai-rust', 'medinovai-go', 'medinovai-d',
            'medinovai-nim', 'medinovai-crystal', 'medinovai-julia',
            'medinovai-r', 'medinovai-matlab', 'medinovai-octave',
            'medinovai-scilab', 'medinovai-maxima', 'medinovai-sage',
            'medinovai-sympy', 'medinovai-numpy', 'medinovai-scipy',
            'medinovai-pandas', 'medinovai-matplotlib', 'medinovai-seaborn',
            'medinovai-plotly', 'medinovai-bokeh', 'medinovai-altair',
            'medinovai-vega', 'medinovai-d3', 'medinovai-three',
            'medinovai-babylon', 'medinovai-aframe', 'medinovai-webgl',
            'medinovai-webgpu', 'medinovai-webxr', 'medinovai-ar',
            'medinovai-vr', 'medinovai-mr', 'medinovai-ai',
            'medinovai-ml', 'medinovai-dl', 'medinovai-nlp',
            'medinovai-cv', 'medinovai-robotics', 'medinovai-iot',
            'medinovai-edge', 'medinovai-fog', 'medinovai-mist',
            'medinovai-cloud', 'medinovai-hybrid', 'medinovai-multi',
            'medinovai-cross', 'medinovai-platform', 'medinovai-agnostic',
            'medinovai-universal', 'medinovai-global', 'medinovai-local',
            'medinovai-regional', 'medinovai-national', 'medinovai-international',
            'medinovai-enterprise', 'medinovai-business', 'medinovai-consumer',
            'medinovai-b2b', 'medinovai-b2c', 'medinovai-c2c',
            'medinovai-p2p', 'medinovai-o2o', 'medinovai-d2c',
            'medinovai-b2b2c', 'medinovai-marketplace', 'medinovai-platform',
            'medinovai-ecosystem', 'medinovai-network', 'medinovai-community',
            'medinovai-social', 'medinovai-collaborative', 'medinovai-cooperative',
            'medinovai-collective', 'medinovai-consortium', 'medinovai-alliance',
            'medinovai-partnership', 'medinovai-joint', 'medinovai-venture',
            'medinovai-startup', 'medinovai-scaleup', 'medinovai-unicorn',
            'medinovai-decacorn', 'medinovai-hectocorn', 'medinovai-megacorn',
            'medinovai-gigacorn', 'medinovai-teracorn', 'medinovai-petacorn',
            'medinovai-exacorn', 'medinovai-zettacorn', 'medinovai-yottacorn'
        ]

    def _setup_logger(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

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
        
        try:
            response = requests.get(url, headers=headers, timeout=30)
            
            if response.status_code == 200:
                return response
            elif response.status_code == 403:
                if 'rate limit' in response.text.lower():
                    wait_time = 3600  # Wait 1 hour for rate limit reset
                    self.logger.warning(f"⚠️ Rate limit exceeded. Waiting {wait_time} seconds...")
                    time.sleep(wait_time)
                    return self.make_github_request(url, headers)
                else:
                    self.logger.error(f"❌ Forbidden: {response.text}")
                    return None
            elif response.status_code == 404:
                self.logger.debug(f"❌ Not found: {url}")
                return None
            else:
                self.logger.warning(f"⚠️ HTTP {response.status_code}: {response.text}")
                return None
                
        except requests.RequestException as e:
            self.logger.error(f"❌ Request failed: {e}")
            return None

    def discover_org_repositories(self, org_name: str) -> List[Dict]:
        """Discover repositories from a specific organization"""
        self.logger.info(f"🔍 Discovering repositories from organization: {org_name}")
        
        repos = []
        page = 1
        per_page = 100
        
        while True:
            url = f'https://api.github.com/orgs/{org_name}/repos?per_page={per_page}&page={page}&sort=created&direction=desc'
            
            response = self.make_github_request(url)
            if not response:
                break
            
            page_repos = response.json()
            if not page_repos:
                break
            
            repos.extend(page_repos)
            self.logger.info(f"✅ Found {len(page_repos)} repositories in {org_name} (page {page})")
            
            if len(page_repos) < per_page:
                break
            
            page += 1
            time.sleep(2)  # Be respectful to the API
        
        self.logger.info(f"🎉 Organization {org_name} discovery complete: {len(repos)} repositories found")
        return repos

    def discover_user_repositories(self, username: str) -> List[Dict]:
        """Discover repositories from a specific user"""
        self.logger.info(f"🔍 Discovering repositories from user: {username}")
        
        repos = []
        page = 1
        per_page = 100
        
        while True:
            url = f'https://api.github.com/users/{username}/repos?per_page={per_page}&page={page}&sort=created&direction=desc'
            
            response = self.make_github_request(url)
            if not response:
                break
            
            page_repos = response.json()
            if not page_repos:
                break
            
            repos.extend(page_repos)
            self.logger.info(f"✅ Found {len(page_repos)} repositories for user {username} (page {page})")
            
            if len(page_repos) < per_page:
                break
            
            page += 1
            time.sleep(2)  # Be respectful to the API
        
        self.logger.info(f"🎉 User {username} discovery complete: {len(repos)} repositories found")
        return repos

    def check_repository_exists(self, owner: str, repo_name: str) -> Optional[Dict]:
        """Check if a specific repository exists"""
        url = f'https://api.github.com/repos/{owner}/{repo_name}'
        
        response = self.make_github_request(url)
        if response and response.status_code == 200:
            return response.json()
        return None

    def discover_known_repositories(self) -> List[Dict]:
        """Check for known repository names across all organizations and users"""
        self.logger.info("🔍 Checking for known repository names across all targets...")
        
        repos = []
        all_targets = self.target_orgs + self.target_users
        
        for i, repo_name in enumerate(self.repo_patterns, 1):
            if i % 50 == 0:
                self.logger.info(f"🔍 Checking known repos: {i}/{len(self.repo_patterns)}")
            
            for target in all_targets:
                repo_data = self.check_repository_exists(target, repo_name)
                if repo_data:
                    self.logger.info(f"✅ Found repository: {target}/{repo_name}")
                    repos.append(repo_data)
                    break  # Found it, no need to check other targets
            
            # Small delay to be respectful
            time.sleep(0.1)
        
        self.logger.info(f"🎉 Known repositories discovery complete: {len(repos)} repositories found")
        return repos

    def discover_from_local_repos(self) -> List[Dict]:
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
                        
                        if result.returncode == 0:
                            remote_url = result.stdout.strip()
                            # Check if it's from any of our target organizations
                            if any(org in remote_url for org in self.target_orgs):
                                repos.append({
                                    'name': repo_dir.name,
                                    'description': 'Discovered from local repository',
                                    'language': 'Unknown',
                                    'archived': False,
                                    'private': True,
                                    'clone_url': remote_url
                                })
                    except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
                        continue
        
        self.logger.info(f"✅ Found {len(repos)} repositories from local discovery")
        return repos

    def discover_all_repositories_comprehensive(self) -> List[Dict]:
        """Discover all repositories using comprehensive approach"""
        self.logger.info("🚀 Starting comprehensive repository discovery for 130+ repositories...")
        
        all_repos = []
        
        # Strategy 1: Check all organizations
        self.logger.info("📡 Strategy 1: Check all organizations")
        for org in self.target_orgs:
            repos = self.discover_org_repositories(org)
            all_repos.extend(repos)
            time.sleep(5)  # Delay between organizations
        
        # Strategy 2: Check all users
        self.logger.info("👤 Strategy 2: Check all users")
        for user in self.target_users:
            repos = self.discover_user_repositories(user)
            all_repos.extend(repos)
            time.sleep(5)  # Delay between users
        
        # Strategy 3: Check known repository patterns
        self.logger.info("📋 Strategy 3: Check known repository patterns")
        repos = self.discover_known_repositories()
        all_repos.extend(repos)
        
        # Strategy 4: Local discovery
        self.logger.info("💾 Strategy 4: Local discovery")
        repos = self.discover_from_local_repos()
        all_repos.extend(repos)
        
        # Remove duplicates
        unique_repos = {}
        for repo in all_repos:
            repo_name = repo.get('name', '')
            full_name = repo.get('full_name', f"{repo.get('owner', {}).get('login', 'unknown')}/{repo_name}")
            if full_name not in unique_repos:
                unique_repos[full_name] = repo
        
        final_repos = list(unique_repos.values())
        
        self.logger.info(f"🎉 Comprehensive discovery completed! Found {len(final_repos)} unique repositories")
        return final_repos

    def generate_comprehensive_report(self, repos: List[Dict]) -> Dict:
        """Generate comprehensive discovery report"""
        # Generate statistics
        languages = {}
        owners = {}
        total_size = 0
        total_stars = 0
        archived_count = 0
        private_count = 0
        
        for repo in repos:
            lang = repo.get('language', 'Unknown')
            languages[lang] = languages.get(lang, 0) + 1
            
            owner = repo.get('owner', {}).get('login', 'Unknown')
            owners[owner] = owners.get(owner, 0) + 1
            
            total_size += repo.get('size', 0)
            total_stars += repo.get('stargazers_count', 0)
            
            if repo.get('archived', False):
                archived_count += 1
            if repo.get('private', False):
                private_count += 1
        
        report = {
            "discovery_timestamp": datetime.now().isoformat(),
            "total_repositories_found": len(repos),
            "statistics": {
                "total_size_kb": total_size,
                "total_stars": total_stars,
                "average_size_kb": round(total_size / len(repos)) if repos else 0,
                "average_stars": round(total_stars / len(repos)) if repos else 0,
                "archived_repositories": archived_count,
                "private_repositories": private_count,
                "public_repositories": len(repos) - private_count
            },
            "languages": languages,
            "owners": owners,
            "repositories": repos
        }
        
        return report

    def save_comprehensive_results(self, report: Dict):
        """Save comprehensive discovery results to files"""
        # Save full report
        with open('comprehensive_130_repo_discovery_report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save repository list for cloning
        repo_list = []
        for repo in report['repositories']:
            repo_list.append({
                'name': repo['name'],
                'full_name': repo.get('full_name', ''),
                'clone_url': repo.get('clone_url', ''),
                'description': repo.get('description', ''),
                'language': repo.get('language', ''),
                'size': repo.get('size', 0),
                'archived': repo.get('archived', False),
                'private': repo.get('private', False),
                'owner': repo.get('owner', {}).get('login', 'Unknown')
            })
        
        with open('all_130_repos_for_cloning.json', 'w') as f:
            json.dump(repo_list, f, indent=2)
        
        # Save simple list for scripts
        with open('all_130_repos_names.txt', 'w') as f:
            for repo in report['repositories']:
                f.write(f"{repo['name']}\n")
        
        self.logger.info(f"✅ Saved {len(report['repositories'])} repositories to files")

    def run_comprehensive_discovery(self):
        """Run the comprehensive discovery process"""
        self.logger.info("🚀 Starting comprehensive 130 repository discovery")
        
        # Discover repositories
        repos = self.discover_all_repositories_comprehensive()
        
        # Generate report
        report = self.generate_comprehensive_report(repos)
        
        # Save results
        self.save_comprehensive_results(report)
        
        # Print summary
        self.logger.info(f"🎉 Comprehensive discovery completed!")
        self.logger.info(f"📊 Total repositories found: {report['total_repositories_found']}")
        self.logger.info(f"📊 Total size: {report['statistics']['total_size_kb']:,} KB")
        self.logger.info(f"📊 Total stars: {report['statistics']['total_stars']:,}")
        self.logger.info(f"📊 Archived: {report['statistics']['archived_repositories']}")
        self.logger.info(f"📊 Private: {report['statistics']['private_repositories']}")
        self.logger.info(f"📊 Public: {report['statistics']['public_repositories']}")
        
        self.logger.info("\nTop languages:")
        for lang, count in sorted(report['languages'].items(), key=lambda x: x[1], reverse=True)[:10]:
            self.logger.info(f"  {lang}: {count} repos")
        
        self.logger.info("\nTop owners:")
        for owner, count in sorted(report['owners'].items(), key=lambda x: x[1], reverse=True)[:10]:
            self.logger.info(f"  {owner}: {count} repos")
        
        return report

if __name__ == "__main__":
    finder = Comprehensive130RepoFinder()
    report = finder.run_comprehensive_discovery()
