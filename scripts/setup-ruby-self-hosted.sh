#!/bin/bash
# Setup script for self-hosted GitHub Actions runners
# This script installs Ruby using rbenv for self-hosted runners

set -e

RUBY_VERSION=${1:-3.2.0}
RUNNER_TOOL_CACHE=${RUNNER_TOOL_CACHE:-/opt/hostedtoolcache}

echo "Setting up Ruby $RUBY_VERSION for self-hosted runner..."

# Check if Ruby is already installed in the tool cache
if [ -f "$RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION/x64.complete" ]; then
    echo "Ruby $RUBY_VERSION already installed in tool cache"
    exit 0
fi

# Install rbenv if not present
if ! command -v rbenv &> /dev/null; then
    echo "Installing rbenv..."
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
fi

# Install ruby-build if not present
if ! command -v ruby-build &> /dev/null; then
    echo "Installing ruby-build..."
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Create tool cache directory
sudo mkdir -p "$RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION"

# Install Ruby to the tool cache
echo "Installing Ruby $RUBY_VERSION to $RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION/x64..."
sudo ruby-build "$RUBY_VERSION" "$RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION/x64"

# Mark as complete
sudo touch "$RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION/x64.complete"

# Set permissions
sudo chown -R $(whoami):$(whoami) "$RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION"

echo "Ruby $RUBY_VERSION installed successfully!"
echo "Path: $RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION/x64"

# Test the installation
"$RUNNER_TOOL_CACHE/Ruby/$RUBY_VERSION/x64/bin/ruby" --version