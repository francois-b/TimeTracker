import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timeTracker: TimeTracker!
    var menu: NSMenu!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("=== TimeTracker Starting ===")

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("Status item created: \(statusItem != nil)")

        // Initialize time tracker
        timeTracker = TimeTracker()
        print("Time tracker initialized")

        // Set initial button image (gray dot when nothing is active)
        updateStatusBarButton()

        // Build menu
        buildMenu()
        print("Menu built and attached")

        // Set up timer to update menu every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenu()
        }

        print("=== TimeTracker Startup Complete ===")
    }

    func buildMenu() {
        menu = NSMenu()

        // Add activity items
        for activity in Activity.allCases {
            let item = NSMenuItem(
                title: activity.displayName,
                action: #selector(activitySelected(_:)),
                keyEquivalent: ""
            )
            item.tag = activity.rawValue
            item.target = self
            item.image = createSmallDotImage(color: activity.color)
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Add times section
        menu.addItem(NSMenuItem(title: "Total Times:", action: nil, keyEquivalent: ""))

        for activity in Activity.allCases {
            let timeItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            timeItem.tag = 100 + activity.rawValue // Offset to identify time items
            menu.addItem(timeItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Add reset option
        let resetItem = NSMenuItem(
            title: "Reset All Times",
            action: #selector(resetAllTimes),
            keyEquivalent: ""
        )
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(NSMenuItem.separator())

        // Add quit option
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenu()
    }

    func updateMenu() {
        // Update status bar button with colored dot
        updateStatusBarButton()

        // Update checkmarks for active activity
        for activity in Activity.allCases {
            if let item = menu.item(withTag: activity.rawValue) {
                item.state = (timeTracker.currentActivity == activity) ? .on : .off
            }
        }

        // Update time displays
        for activity in Activity.allCases {
            if let item = menu.item(withTag: 100 + activity.rawValue) {
                let time = timeTracker.getTotalTime(for: activity)
                item.title = "  \(activity.displayName): \(formatTime(time))"
            }
        }
    }

    func updateStatusBarButton() {
        guard let button = statusItem.button else { return }

        let color: NSColor
        if let currentActivity = timeTracker.currentActivity {
            color = currentActivity.color
        } else {
            // Gray when nothing is active
            color = NSColor(white: 0.5, alpha: 1.0)
        }

        button.image = createDotImage(color: color)
        button.title = ""
    }

    func createDotImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()

        // Draw a circle
        let rect = NSRect(x: 2, y: 2, width: 14, height: 14)
        let path = NSBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    func createSmallDotImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)

        image.lockFocus()

        // Draw a smaller circle for menu items
        let rect = NSRect(x: 3, y: 3, width: 10, height: 10)
        let path = NSBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    @objc func activitySelected(_ sender: NSMenuItem) {
        guard let activity = Activity(rawValue: sender.tag) else { return }

        if timeTracker.currentActivity == activity {
            // Deselect if clicking the same activity
            timeTracker.stopTracking()
        } else {
            // Select new activity
            timeTracker.startTracking(activity: activity)
        }

        updateMenu()
    }

    @objc func resetAllTimes() {
        let alert = NSAlert()
        alert.messageText = "Reset All Times?"
        alert.informativeText = "This will reset all tracked times to zero. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            timeTracker.resetAllTimes()
            updateMenu()
        }
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timeTracker.stopTracking()
    }
}
