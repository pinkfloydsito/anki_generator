---
name: Ruby Setup Issue
about: Report problems with Ruby installation or GitHub Actions
title: '[RUBY SETUP] '
labels: 'ci, ruby, setup'
assignees: ''
---

## Ruby Setup Issue

### Environment
- **Runner Type**: [ ] GitHub-hosted [ ] Self-hosted
- **OS**: (e.g., ubuntu-24.04, ubuntu-latest, macOS)
- **Ruby Version**: (e.g., 3.0, 3.1, 3.2)
- **Workflow**: (e.g., ruby.yml, ci.yml)

### Problem Description
<!-- Describe the Ruby setup issue you're experiencing -->

### Error Message
```
<!-- Paste the full error message here -->
```

### Steps to Reproduce
1. 
2. 
3. 

### Expected Behavior
<!-- What should happen -->

### Actual Behavior
<!-- What actually happens -->

### Additional Context
<!-- Any other context about the problem -->

### Possible Solutions
For self-hosted runners, you can try:

1. **Manual Ruby Installation**:
   ```bash
   ./scripts/setup-ruby-self-hosted.sh 3.2.0
   ```

2. **Use the CI workflow instead**:
   - The `ci.yml` workflow has better self-hosted runner support
   - Enable the self-hosted job by setting `if: true`

3. **Check runner tool cache**:
   ```bash
   ls -la /opt/hostedtoolcache/Ruby/
   ```

4. **Verify Ruby installation**:
   ```bash
   ruby --version
   gem --version
   ```