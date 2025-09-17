#!/bin/bash

# GitHub Authentication Setup Script
# This script helps set up GitHub authentication for accessing private repositories

set -euo pipefail

echo "🔐 GitHub Authentication Setup for MedinovAI Implementation"
echo "=========================================================="

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Please install GitHub CLI first:"
    echo "  - macOS: brew install gh"
    echo "  - Linux: https://cli.github.com/"
    exit 1
fi

echo "✅ GitHub CLI is available"

# Check current authentication status
echo "🔍 Checking current authentication status..."
if gh auth status >/dev/null 2>&1; then
    echo "✅ GitHub CLI is already authenticated"
    gh auth status
else
    echo "❌ GitHub CLI is not authenticated"
    echo ""
    echo "🔑 To authenticate with GitHub CLI, you have several options:"
    echo ""
    echo "Option 1: Interactive login (recommended)"
    echo "  Run: gh auth login"
    echo "  Follow the prompts to authenticate"
    echo ""
    echo "Option 2: Use existing PAT"
    echo "  Run: gh auth login --with-token < your_pat_file"
    echo "  Or: echo 'your_pat' | gh auth login --with-token"
    echo ""
    echo "Option 3: Set environment variable"
    echo "  export GITHUB_TOKEN='your_pat'"
    echo "  Then run: gh auth login --with-token"
    echo ""
    echo "📋 Required PAT permissions:"
    echo "  - repo (Full control of private repositories)"
    echo "  - admin:org (Full control of orgs and teams)"
    echo "  - admin:public_key (Full control of user public keys)"
    echo "  - admin:repo_hook (Full control of repository hooks)"
    echo "  - admin:org_hook (Full control of organization hooks)"
    echo "  - user (Update ALL user data)"
    echo "  - delete_repo (Delete repositories)"
    echo "  - admin:gpg_key (Full control of user gpg keys)"
    echo ""
    echo "🚀 After authentication, run this script again to verify access"
    exit 1
fi

# Test access to the organization
echo ""
echo "🧪 Testing access to myonsite-healthcare organization..."
if curl -s -H "Authorization: token $(gh auth token)" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/myonsite-healthcare" | jq -r '.login' 2>/dev/null | grep -q "myonsite-healthcare"; then
    echo "✅ Successfully authenticated with myonsite-healthcare organization"
else
    echo "❌ Failed to access myonsite-healthcare organization"
    echo "Please check your PAT permissions and try again"
    exit 1
fi

# Test access to repositories
echo ""
echo "🔍 Testing access to repositories..."
REPO_COUNT=$(curl -s -H "Authorization: token $(gh auth token)" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/myonsite-healthcare/repos?per_page=1" | jq 'length' 2>/dev/null || echo "0")

if [[ "$REPO_COUNT" -gt 0 ]]; then
    echo "✅ Successfully accessed repositories (found $REPO_COUNT+ repositories)"
else
    echo "❌ Failed to access repositories"
    echo "Please check your PAT permissions and organization access"
    exit 1
fi

# Test access to medinovai-infrastructure specifically
echo ""
echo "🔍 Testing access to medinovai-infrastructure repository..."
if curl -s -H "Authorization: token $(gh auth token)" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/myonsite-healthcare/medinovai-infrastructure" | jq -r '.name' 2>/dev/null | grep -q "medinovai-infrastructure"; then
    echo "✅ Successfully accessed medinovai-infrastructure repository"
else
    echo "❌ Failed to access medinovai-infrastructure repository"
    echo "Please check your PAT permissions and repository access"
    exit 1
fi

echo ""
echo "🎉 GitHub authentication setup complete!"
echo "✅ You now have full access to private repositories"
echo "🚀 Ready to proceed with MedinovAI implementation"

