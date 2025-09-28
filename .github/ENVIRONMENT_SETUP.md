# GitHub Environment Variables Setup Guide

This document explains how to configure environment variables and secrets for the RCMD project CI/CD pipeline.

## 🔐 Repository Secrets

Navigate to: **Settings** → **Secrets and variables** → **Actions** → **Secrets** tab

### Required Secrets

```bash
# Database (Production)
POSTGRES_URL_PRODUCTION=postgresql://username:password@host:5432/rcmd_production

# Database (Staging)
POSTGRES_URL_STAGING=postgresql://username:password@staging-host:5432/rcmd_staging

# API Keys & Tokens
RCLONE_CONFIG_KEY=your_rclone_encryption_key
NOTIFICATION_WEBHOOK=https://your-webhook-url.com/webhook

# Optional: Docker Hub (if not using GitHub Container Registry)
DOCKER_USERNAME=your_docker_username
DOCKER_PASSWORD=your_docker_password
```

## 📋 Repository Variables

Navigate to: **Settings** → **Secrets and variables** → **Actions** → **Variables** tab

### Required Variables

```bash
# Application Settings
NODE_ENV=production
PORT=3000
TZ=UTC

# Allowed Hosts (Production)
VITE_ALLOWED_HOSTS_PRODUCTION=rcmd.yourdomain.com,.yourdomain.com

# Allowed Hosts (Staging)
VITE_ALLOWED_HOSTS_STAGING=rcmd-staging.yourdomain.com,.staging.yourdomain.com

# Database Connection (Non-sensitive)
POSTGRES_HOST_PRODUCTION=your-production-db-host.com
POSTGRES_USER_PRODUCTION=rcmd_user
POSTGRES_DB_PRODUCTION=rcmd_production

POSTGRES_HOST_STAGING=your-staging-db-host.com
POSTGRES_USER_STAGING=rcmd_user
POSTGRES_DB_STAGING=rcmd_staging

# Docker Settings
PUID=1000
PGID=1000
```

## 🌍 Environment-Specific Settings

### Staging Environment

Navigate to: **Settings** → **Environments** → **Create environment: staging**

**Environment Secrets:**
- `POSTGRES_URL_STAGING`
- `RCLONE_CONFIG_KEY_STAGING` (if different)

**Environment Variables:**
- `VITE_ALLOWED_HOSTS_STAGING`
- `NODE_ENV=staging`

**Protection Rules:**
- ✅ Require branches to be up to date before merging
- ✅ Restrict pushes that create files with new files

### Production Environment

Navigate to: **Settings** → **Environments** → **Create environment: production**

**Environment Secrets:**
- `POSTGRES_URL_PRODUCTION`
- `RCLONE_CONFIG_KEY_PRODUCTION`

**Environment Variables:**
- `VITE_ALLOWED_HOSTS_PRODUCTION`
- `NODE_ENV=production`

**Protection Rules:**
- ✅ Required reviewers: 1
- ✅ Restrict pushes that create files with new files
- ✅ Allow administrators to bypass configured protection rules

## 🚀 Usage in Workflows

### In Workflow Files

```yaml
# Using Repository Variables
env:
  NODE_ENV: ${{ vars.NODE_ENV }}
  VITE_ALLOWED_HOSTS: ${{ vars.VITE_ALLOWED_HOSTS_PRODUCTION }}

# Using Repository Secrets
env:
  POSTGRES_URL: ${{ secrets.POSTGRES_URL_PRODUCTION }}

# Using Environment-specific Variables
- name: Deploy to production
  environment: production
  env:
    DATABASE_URL: ${{ secrets.POSTGRES_URL_PRODUCTION }}
    ALLOWED_HOSTS: ${{ vars.VITE_ALLOWED_HOSTS_PRODUCTION }}
```

### In Docker Builds

```yaml
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    build-args: |
      NODE_ENV=${{ vars.NODE_ENV }}
      VITE_ALLOWED_HOSTS=${{ vars.VITE_ALLOWED_HOSTS_PRODUCTION }}
```

## 🔧 Local Development

For local development, copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:
```bash
PUID=1000
PGID=1000
VITE_ALLOWED_HOSTS=localhost,127.0.0.1,.local

# Optional: Local database
POSTGRES_URL=postgresql://username:password@localhost:5432/rcmd_dev
```

## 📝 Best Practices

### Secrets Management
- ✅ Never commit secrets to git
- ✅ Use different secrets for staging/production
- ✅ Rotate secrets regularly
- ✅ Use environment protection rules for production

### Variables Management
- ✅ Use variables for non-sensitive configuration
- ✅ Keep environment-specific settings separate
- ✅ Document all required variables
- ✅ Use descriptive names

### Security
- ✅ Enable environment protection rules
- ✅ Require code review for production deployments
- ✅ Use least privilege principle
- ✅ Monitor secret access logs

## 🆘 Troubleshooting

### Common Issues

1. **Secret not found**
   ```
   Error: Secret POSTGRES_URL not found
   ```
   - Check secret name spelling
   - Verify secret is set at correct level (repo/environment)

2. **Variable not accessible**
   ```
   Error: Variable NODE_ENV is empty
   ```
   - Ensure variable is set in repository variables
   - Check environment context

3. **Permission denied**
   ```
   Error: Access denied to environment production
   ```
   - Check environment protection rules
   - Ensure user has required permissions

### Debug Commands

Add to workflow for debugging:
```yaml
- name: Debug Environment
  run: |
    echo "Node ENV: ${{ vars.NODE_ENV }}"
    echo "Allowed Hosts: ${{ vars.VITE_ALLOWED_HOSTS_PRODUCTION }}"
    echo "Database Host: ${{ vars.POSTGRES_HOST_PRODUCTION }}"
    # Don't echo secrets!
```

## 📚 References

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Variables](https://docs.github.com/en/actions/learn-github-actions/variables)
- [Environment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)