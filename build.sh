#!/bin/bash
set -e

echo "Building iOS 120Hz mod for Geometry Dash..."

# Check for Geode CLI
if ! command -v geode &> /dev/null; then
    echo "Error: geode CLI not found. Install from https://github.com/geode-sdk/cli"
    exit 1
fi

# Build for iOS
geode build --target ios

echo "Build complete! Install the .geode file with your sideloader."
