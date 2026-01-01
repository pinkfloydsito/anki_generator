# CI/CD Setup Guide

This document explains the GitHub Actions workflows and how to handle Ruby setup issues.

## Workflows Overview

### 1. `ruby.yml` - Main CI Pipeline
- **Trigger**: Push/PR to main branch
- **Ruby Versions**: 3.0, 3.1, 3.2
- **Actions**: Test, lint, build
- **Fixed Issues**: Updated to use `ruby/setup-ruby@v1` instead of specific commit hash

### 2. `ci.yml` - Extended CI Pipeline
- **Trigger**: Push/PR to main/develop branches
- **Ruby Versions**: 3.0, 3.1, 3.2, 3.3
- **OS Support**: Ubuntu, macOS
- **Features**: 
  - Multi-OS testing
  - Self-hosted runner support (disabled by default)
  - Gem verification
  - Artifact upload

### 3. `release.yml` - Automated Releases
- **Trigger**: Git tags (v*)
- **Actions**: Test, build, create GitHub release
- **Artifacts**: Uploads gem file to release
- **Optional**: RubyGems publishing (commented out)

### 4. `manual-test.yml` - Manual Testing
- **Trigger**: Manual workflow dispatch
- **Features**: 
  - Choose Ruby version
  - Optional demo runs
  - Full CLI testing

### 5. `dependabot-auto-merge.yml` - Dependency Management
- **Trigger**: Dependabot PRs
- **Actions**: Auto-merge minor/patch updates after tests pass

## Ruby Setup Issues

### Problem: Self-Hosted Runner Detection
```
Error: The current runner (ubuntu-24.04-x64) was detected as self-hosted because the platform does not match a GitHub-hosted runner image
```

### Solutions:

#### Option 1: Use Updated Workflow
The `ruby.yml` workflow has been updated to use `ruby/setup-ruby@v1` which handles newer Ubuntu versions better.

#### Option 2: Manual Ruby Installation (Self-Hosted Runners)
```bash
# Run the setup script
./scripts/setup-ruby-self-hosted.sh 3.2.0

# Or manually:
ruby-build 3.2.0 /opt/hostedtoolcache/Ruby/3.2.0/x64
touch /opt/hostedtoolcache/Ruby/3.2.0/x64.complete
```

#### Option 3: Enable Self-Hosted Job in CI
In `.github/workflows/ci.yml`, change:
```yaml
if: false  # Set to true if you want to enable self-hosted testing
```
to:
```yaml
if: true
```

#### Option 4: Use Different Runner
Change the runner in your workflow:
```yaml
runs-on: ubuntu-22.04  # Instead of ubuntu-latest
```

## Testing Locally

Before pushing, test locally:
```bash
# Run all tests
bundle exec rake test

# Build gem
bundle exec rake build

# Install and test CLI
bundle exec rake install_local
anki_generator help
```

## Release Process

1. **Update version** in `anki_generator.gemspec`
2. **Update CHANGELOG.md** with new version
3. **Commit changes**:
   ```bash
   git add .
   git commit -m "Bump version to 1.2.0"
   ```
4. **Create and push tag**:
   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```
5. **GitHub Actions will**:
   - Run tests
   - Build gem
   - Create GitHub release
   - Upload gem artifact

## Troubleshooting

### Ruby Version Issues
- Check supported Ruby versions in `.ruby-version` or gemspec
- Ensure bundler compatibility
- Test with multiple Ruby versions locally using rbenv/rvm

### Dependency Issues
- Run `bundle update` to update dependencies
- Check for security vulnerabilities: `bundle audit`
- Review Dependabot PRs regularly

### Build Issues
- Ensure all files are included in gemspec
- Check for missing dependencies
- Verify executable permissions on scripts

### Self-Hosted Runner Issues
- Ensure Ruby is in PATH
- Check tool cache permissions
- Verify network access to rubygems.org
- Use the provided setup script

## Monitoring

- Check GitHub Actions tab for workflow status
- Review failed builds and logs
- Monitor dependency updates from Dependabot
- Watch for security alerts

## Best Practices

1. **Always test locally** before pushing
2. **Keep dependencies updated** via Dependabot
3. **Use semantic versioning** for releases
4. **Update CHANGELOG.md** for each release
5. **Test on multiple Ruby versions** before major releases
6. **Monitor CI/CD pipeline** health regularly