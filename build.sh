#!/bin/bash

# Build script for TimeTracker menu bar app

echo "Building TimeTracker..."

# Build with Swift Package Manager
swift build -c release

if [ $? -ne 0 ]; then
    echo "✗ Build failed"
    exit 1
fi

# Create app bundle structure
mkdir -p TimeTracker.app/Contents/MacOS
mkdir -p TimeTracker.app/Contents/Resources

# Copy the compiled binary
cp .build/release/TimeTracker TimeTracker.app/Contents/MacOS/TimeTracker

# Copy Info.plist
cp Info.plist TimeTracker.app/Contents/Info.plist

echo "✓ Build successful!"
echo "Run with: open TimeTracker.app"
