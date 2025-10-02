#!/bin/bash
#
# MCP Container Monitor
# Checks for rogue MCP containers and alerts if too many are running
#
# Usage: ./scripts/check_mcp_containers.sh
#

set -e

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 MCP Container Monitor"
echo "========================"
echo ""

# Check for GitLab MCP containers
GITLAB_COUNT=$(docker ps --filter "ancestor=mcp/gitlab:latest" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')

echo "GitLab MCP Containers: $GITLAB_COUNT"

if [ "$GITLAB_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ No GitLab MCP containers running (expected with npm-based config)${NC}"
elif [ "$GITLAB_COUNT" -le 2 ]; then
    echo -e "${YELLOW}⚠️  Warning: $GITLAB_COUNT GitLab MCP container(s) detected${NC}"
    echo "   This might be normal if using Docker-based MCP config"
else
    echo -e "${RED}❌ ALERT: $GITLAB_COUNT GitLab MCP containers running!${NC}"
    echo "   Expected: 0 (npm-based) or 1-2 (Docker-based)"
    echo ""
    echo "Container details:"
    docker ps --filter "ancestor=mcp/gitlab:latest" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"
    echo ""
    echo "To clean up, run:"
    echo "  docker stop \$(docker ps --filter 'ancestor=mcp/gitlab:latest' -q)"
    exit 1
fi

echo ""

# Check for other MCP containers
OTHER_MCP=$(docker ps --format "{{.Image}}" | grep -i "mcp/" | grep -v "mcp/gitlab" | wc -l | tr -d ' ')

if [ "$OTHER_MCP" -gt 0 ]; then
    echo "Other MCP Containers: $OTHER_MCP"
    docker ps --filter "ancestor=*mcp/*" --format "table {{.Image}}\t{{.Names}}\t{{.Status}}"
else
    echo -e "${GREEN}✅ No other MCP containers detected${NC}"
fi

echo ""

# Check MCP configuration
if [ -f ~/.cursor/mcp.json ]; then
    echo "MCP Configuration:"
    if grep -q '"docker"' ~/.cursor/mcp.json 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Docker-based MCP configuration detected${NC}"
        echo "   Consider migrating to npm-based approach"
    else
        echo -e "${GREEN}✅ Using npm-based MCP configuration${NC}"
    fi
fi

echo ""
echo "✅ MCP container check complete"

