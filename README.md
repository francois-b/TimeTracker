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
- Automatically logs activity changes to Neon PostgreSQL database
- Sends HTTP status updates to localhost:3000/api/data
- Comprehensive logging to `app.log` file in the app directory

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

## Database Integration

The app automatically logs all activity changes to a Neon PostgreSQL database. Each time you start or stop tracking an activity, a record is inserted into the `time_tracking` table with:
- `activity`: The activity name (or "none" when not tracking)
- `is_active`: Boolean indicating if activity is starting or stopping
- `timestamp`: ISO8601 timestamp of the change

**Prerequisites:** 
1. Set the `NEON_PASSWORD` environment variable with your Neon database password:
```bash
export NEON_PASSWORD="your_neon_password_here"
```

2. Add it to your shell profile to make it persistent:
```bash
echo 'export NEON_PASSWORD="your_neon_password_here"' >> ~/.zshrc
source ~/.zshrc
```

The database connection and table creation happen automatically when you change activities.

## Logging

The app writes detailed logs to `app.log` in the same directory as the TimeTracker.app bundle. Each log entry includes:
- ISO8601 timestamp
- Source file and line number
- Function name
- Log message

Logs capture all key events including:
- App startup and shutdown
- Activity selection and tracking
- Database writes
- HTTP requests
- Check-in prompts and user responses
- Time resets

To view logs in real-time:
```bash
tail -f app.log
```

## Architecture

- `TimeTrackerApp.swift`: Main application delegate and menu bar UI
- `TimeTracker.swift`: Core time tracking logic and data persistence
- `Info.plist`: App configuration (LSUIElement=true makes it menu-bar only)

The app uses UserDefaults to persist time data between launches.
