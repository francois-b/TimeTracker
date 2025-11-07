import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timeTracker: TimeTracker!
    var menu: NSMenu!
    var checkInTimer: Timer?

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

    func sendStatusUpdate(activity: String?, isActive: Bool) {
        guard let url = URL(string: "http://localhost:3000/api/data") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "activity": activity ?? "none",
            "isActive": isActive,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending status update: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Status update sent. Response code: \(httpResponse.statusCode)")
            }
        }
        task.resume()
    }

    func startCheckInTimer() {
        // Cancel existing timer if any
        checkInTimer?.invalidate()

        // Start new timer for 15 minutes (900 seconds)
        checkInTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: false) { [weak self] _ in
            self?.showCheckInPrompt()
        }
    }

    func stopCheckInTimer() {
        checkInTimer?.invalidate()
        checkInTimer = nil
    }

    func showCheckInPrompt() {
        guard let currentActivity = timeTracker.currentActivity else { return }

        let alert = NSAlert()
        alert.messageText = "Still working on \(currentActivity.displayName)?"
        alert.informativeText = "You've been tracking \(currentActivity.displayName) for 15 minutes. Would you like to continue or switch to a different activity?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Change Activity")
        alert.addButton(withTitle: "Stop Tracking")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            // Continue - restart the timer
            startCheckInTimer()

        case .alertSecondButtonReturn:
            // Change Activity - show selection dialog
            showActivitySelection()

        case .alertThirdButtonReturn:
            // Stop tracking
            timeTracker.stopTracking()
            sendStatusUpdate(activity: nil, isActive: false)
            stopCheckInTimer()
            updateMenu()

        default:
            break
        }
    }

    func showActivitySelection() {
        let alert = NSAlert()
        alert.messageText = "Select New Activity"
        alert.informativeText = "Choose which activity to track:"
        alert.alertStyle = .informational

        // Add a button for each activity
        for activity in Activity.allCases {
            alert.addButton(withTitle: activity.displayName)
        }
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        // Map response to activity (first button = .alertFirstButtonReturn = 1000)
        let buttonIndex = response.rawValue - 1000

        if buttonIndex >= 0 && buttonIndex < Activity.allCases.count {
            let selectedActivity = Activity.allCases[buttonIndex]
            timeTracker.startTracking(activity: selectedActivity)
            sendStatusUpdate(activity: selectedActivity.displayName, isActive: true)
            startCheckInTimer()
            updateMenu()
        }
        // If Cancel or out of bounds, do nothing
    }

    @objc func activitySelected(_ sender: NSMenuItem) {
        guard let activity = Activity(rawValue: sender.tag) else { return }

        if timeTracker.currentActivity == activity {
            // Deselect if clicking the same activity
            timeTracker.stopTracking()
            sendStatusUpdate(activity: nil, isActive: false)
            stopCheckInTimer()
        } else {
            // Select new activity
            timeTracker.startTracking(activity: activity)
            sendStatusUpdate(activity: activity.displayName, isActive: true)
            startCheckInTimer()
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
        stopCheckInTimer()
        timeTracker.stopTracking()
    }
}
