# Cursor MCP Configuration Guide

## Overview
This document describes the MCP (Model Context Protocol) server configuration for the MedinovAI infrastructure project.

## Current Configuration

### Location
- **File**: `~/.cursor/mcp.json`
- **Backup**: `~/.cursor/mcp.json.backup`
- **Repository Copy**: `docs/cursor-config/mcp.json.old` (legacy Docker-based config)

### Active MCP Servers

#### 1. GitLab MCP Server
**Purpose**: Interact with GitLab repositories at git.myonsitehealthcare.com

**Configuration**:
```json
{
  "gitlab": {
    "command": "mcp-server-gitlab",
    "args": [],
    "env": {
      "GITLAB_PERSONAL_ACCESS_TOKEN": "<redacted>",
      "GITLAB_API_URL": "https://git.myonsitehealthcare.com/api/v4"
    }
  }
}
```

**Installation**:
```bash
npm install -g @modelcontextprotocol/server-gitlab
```

**Binary Location**: `/opt/homebrew/bin/mcp-server-gitlab`

#### 2. Playwright MCP Server
**Purpose**: Web automation, testing, and browser interactions

**Configuration**:
```json
{
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest"]
  }
}
```

## Migration History

### October 1, 2025 - Docker to Native Binary Migration

**Problem**: 
- 30+ Docker containers (`mcp/gitlab:latest`) were spawned and remained running
- Each container consumed ~250MB memory
- Total resource waste: ~7.5GB RAM + CPU overhead

**Root Cause**:
- Previous configuration used Docker-based MCP server
- Multiple Cursor sessions spawned multiple containers
- Containers failed to self-clean despite `--rm` flag

**Solution**:
- Migrated from Docker-based to npm-based GitLab MCP server
- Stopped and removed all 30 Docker containers
- Updated `~/.cursor/mcp.json` to use native binary

**Benefits**:
- ✅ No Docker container spawning
- ✅ Faster MCP server startup
- ✅ ~7.5GB RAM freed
- ✅ Reduced CPU overhead
- ✅ Cleaner Docker environment

## Monitoring

### Check for Rogue MCP Containers
```bash
# Should return 0
docker ps --filter "ancestor=mcp/gitlab:latest" --format "{{.Names}}" | wc -l
```

### Verify MCP Server Binary
```bash
which mcp-server-gitlab
# Expected: /opt/homebrew/bin/mcp-server-gitlab
```

### Test MCP Server
```bash
# Should request GITLAB_PERSONAL_ACCESS_TOKEN
npx @modelcontextprotocol/server-gitlab --help
```

## Security Notes

⚠️ **Important**: 
- Never commit `~/.cursor/mcp.json` with actual tokens to version control
- Rotate GitLab Personal Access Token periodically
- Use minimal required permissions for PAT

## Troubleshooting

### MCP Server Not Starting
1. Check if binary exists: `which mcp-server-gitlab`
2. Reinstall if needed: `npm install -g @modelcontextprotocol/server-gitlab`
3. Verify JSON syntax: `cat ~/.cursor/mcp.json | python3 -m json.tool`
4. Restart Cursor

### Docker Containers Reappearing
1. Check MCP configuration: `cat ~/.cursor/mcp.json`
2. Ensure using native binary, not Docker command
3. Stop rogue containers: `docker stop $(docker ps --filter "ancestor=mcp/gitlab:latest" -q)`

### GitLab Connection Issues
1. Verify GitLab API URL is accessible
2. Check Personal Access Token validity
3. Ensure token has required scopes (api, read_repository)

## Alternative: Disable GitLab MCP

If GitLab MCP is not needed, remove from configuration:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

Then restart Cursor.

## References

- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [Cursor MCP Guide](https://docs.cursor.com/mcp)
- MedinovAI Infrastructure: [.cursorrules](.cursorrules)

