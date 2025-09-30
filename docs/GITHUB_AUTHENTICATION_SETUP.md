# GitHub Authentication Setup Guide

## 🚨 CRITICAL: GitHub Authentication Required

The GitHub migration requires proper authentication to access repositories. Follow these steps to complete the setup:

## Step 1: GitHub CLI Authentication

### Option A: Interactive Login (Recommended)
```bash
# Run the GitHub CLI authentication
gh auth login

# Follow the prompts:
# 1. Choose "GitHub.com"
# 2. Choose "HTTPS" as protocol
# 3. Choose "Yes" to authenticate Git with GitHub credentials
# 4. Choose "Login with a web browser"
# 5. Copy the one-time code and press Enter
# 6. Complete authentication in your browser
```

### Option B: Token-based Authentication
```bash
# Create a Personal Access Token at: https://github.com/settings/tokens
# Required scopes: repo, read:org, read:user, admin:org

# Authenticate with token
gh auth login --with-token < your_token_here
```

## Step 2: Verify Authentication

```bash
# Check authentication status
gh auth status

# Test API access
gh api user

# Check rate limits
gh api rate_limit
```

## Step 3: Required Permissions

Ensure your GitHub account has the following permissions:
- **repo**: Full control of private repositories
- **read:org**: Read org and team membership
- **read:user**: Read user profile data
- **admin:org**: Full control of orgs and teams (if migrating org repos)

## Step 4: Test Repository Access

```bash
# List your repositories
gh repo list --limit 5

# List organization repositories (if applicable)
gh repo list <organization> --limit 5
```

## Step 5: Resume Migration

Once authentication is complete, run:

```bash
# Resume GitHub access setup
cd /Users/dev1/github/medinovai-infrastructure
./scripts/github_access_setup.sh

# Validate access
./scripts/validate_github_access.sh

# Check system health
./scripts/health_check.sh
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Ensure you have the correct permissions
   - Check if 2FA is enabled and use a Personal Access Token
   - Verify network connectivity

2. **Rate Limit Exceeded**
   - Wait for rate limit reset
   - Use authenticated requests to increase limits
   - Implement retry logic in scripts

3. **Repository Access Denied**
   - Check repository permissions
   - Verify organization membership
   - Ensure token has required scopes

### Support Commands

```bash
# Check current authentication
gh auth status

# Refresh authentication
gh auth refresh

# Logout and re-authenticate
gh auth logout
gh auth login
```

## Security Notes

- Never commit tokens to version control
- Use environment variables for sensitive data
- Regularly rotate Personal Access Tokens
- Monitor token usage and permissions

## Next Steps

After completing authentication:
1. Run `./scripts/github_access_setup.sh`
2. Proceed to Task 2: Repository Discovery
3. Continue with the BMAD Method migration plan

---

**Status**: Authentication required before proceeding
**Next Action**: Complete GitHub authentication setup
