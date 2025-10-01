#!/bin/bash

# Quick execution script for GitHub push
# Run this after: gh auth login

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║         🚀 MedinovAI GitHub Push - Quick Execution            ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "This script will push all 5 migrated repositories to GitHub."
echo ""
echo "Prerequisites:"
echo "  ✅ 5 repositories ready for push"
echo "  ⏳ GitHub authentication required"
echo ""
read -p "Have you run 'gh auth login'? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Please run: gh auth login"
    echo "Then run this script again."
    exit 1
fi

echo ""
echo "Starting push to GitHub..."
echo ""

./scripts/push_to_github.sh

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ PUSH COMPLETE!                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Verify on GitHub:"
echo "  gh repo list medinovai"
echo ""
