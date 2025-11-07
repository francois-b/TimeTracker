# TimeTracker - Menu Bar Time Tracking App

A simple macOS menu bar application for tracking time spent on different activities.

## Features

- Lives in your macOS menu bar
- Track time for 5 activities:
  - Relax
  - Research
  - Work
  - Content
  - Job Search
- Click an activity to start tracking
- Click again to stop tracking
- View total accumulated time for each activity
- Times are automatically saved and persist between app launches
- Reset all times option

## Building the App

### Option 1: Using Xcode

1. Open Xcode
2. Create a new macOS App project
3. Replace the generated files with the files in this directory
4. Build and run (Cmd+R)

### Option 2: Using Swift Command Line

```bash
# Compile the app
swiftc -o TimeTracker TimeTrackerApp.swift TimeTracker.swift -framework Cocoa -framework SwiftUI

# Run the app
./TimeTracker
```

### Option 3: Create an Xcode Project from Command Line

```bash
# Create a proper app bundle
mkdir -p TimeTracker.app/Contents/MacOS
mkdir -p TimeTracker.app/Contents/Resources

# Compile
swiftc -o TimeTracker.app/Contents/MacOS/TimeTracker TimeTrackerApp.swift TimeTracker.swift -framework Cocoa -framework SwiftUI

# Copy Info.plist
cp Info.plist TimeTracker.app/Contents/Info.plist

# Run
open TimeTracker.app
```

## Usage

1. Launch the app - a clock icon will appear in your menu bar
2. Click the clock icon to open the menu
3. Click on any activity to start tracking time for it (it will show a checkmark)
4. Click the same activity again to stop tracking
5. View accumulated times in the lower section of the menu
6. Use "Reset All Times" to clear all tracked time
7. Use "Quit" to exit the app

## Architecture

- `TimeTrackerApp.swift`: Main application delegate and menu bar UI
- `TimeTracker.swift`: Core time tracking logic and data persistence
- `Info.plist`: App configuration (LSUIElement=true makes it menu-bar only)

The app uses UserDefaults to persist time data between launches.
