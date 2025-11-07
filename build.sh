#!/bin/bash

# Build script for TimeTracker menu bar app

echo "Building TimeTracker..."

# Create app bundle structure
mkdir -p TimeTracker.app/Contents/MacOS
mkdir -p TimeTracker.app/Contents/Resources

# Compile Swift files
swiftc -o TimeTracker.app/Contents/MacOS/TimeTracker \
    main.swift \
    TimeTrackerApp.swift \
    TimeTracker.swift \
    -framework Cocoa \
    -O

if [ $? -eq 0 ]; then
    # Copy Info.plist
    cp Info.plist TimeTracker.app/Contents/Info.plist

    echo "✓ Build successful!"
    echo "Run with: open TimeTracker.app"
else
    echo "✗ Build failed"
    exit 1
fi
