import Cocoa
import Foundation

class Logger {
    static let shared = Logger()
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.timetracker.logger", qos: .utility)
    
    init() {
        // Use the directory where the app bundle is located
        if let bundlePath = Bundle.main.bundlePath as String? {
            let bundleDir = (bundlePath as NSString).deletingLastPathComponent
            logFileURL = URL(fileURLWithPath: bundleDir).appendingPathComponent("app.log")
        } else {
            // Fallback to current directory
            let currentDir = FileManager.default.currentDirectoryPath
            logFileURL = URL(fileURLWithPath: currentDir).appendingPathComponent("app.log")
        }
        log("Logger initialized. Log file: \(logFileURL.path)")
    }
    
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        queue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let filename = (file as NSString).lastPathComponent
            let logMessage = "[\(timestamp)] [\(filename):\(line)] \(function) - \(message)\n"
            
            print(message)
            
            if let data = logMessage.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: self.logFileURL, options: .atomic)
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timeTracker: TimeTracker!
    var menu: NSMenu!
    var checkInTimer: Timer?
    var lastActivityState: Activity?  // Track last activity to detect changes

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.log("=== TimeTracker Starting ===")

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        Logger.shared.log("Status item created: \(statusItem != nil)")

        // Initialize time tracker
        timeTracker = TimeTracker()
        Logger.shared.log("Time tracker initialized")

        // Set initial button image (gray dot when nothing is active)
        updateStatusBarButton()

        // Build menu
        buildMenu()
        Logger.shared.log("Menu built and attached")

        // Set up timer to update menu every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenu()
        }

        Logger.shared.log("=== TimeTracker Startup Complete ===")
    }

    func buildMenu() {
        Logger.shared.log("Building menu")
        menu = NSMenu()

        // Add "Not tracking" option
        let notTrackingItem = NSMenuItem(
            title: "Not tracking",
            action: #selector(notTrackingSelected),
            keyEquivalent: ""
        )
        notTrackingItem.tag = -1
        notTrackingItem.target = self
        notTrackingItem.image = createSmallDotImage(color: NSColor(white: 0.5, alpha: 1.0))
        menu.addItem(notTrackingItem)

        menu.addItem(NSMenuItem.separator())

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

        // Update checkmark for "Not tracking"
        if let notTrackingItem = menu.item(withTag: -1) {
            notTrackingItem.state = (timeTracker.currentActivity == nil) ? .on : .off
        }

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

        let currentActivity = timeTracker.currentActivity
        
        // Only log if the activity state has changed
        if lastActivityState != currentActivity {
            if let activity = currentActivity {
                Logger.shared.log("Status changed: Now tracking \(activity.displayName)")
            } else {
                Logger.shared.log("Status changed: Not tracking")
            }
            lastActivityState = currentActivity
        }
        
        let color: NSColor
        if let activity = currentActivity {
            color = activity.color
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

    func createAlertIcon(color: NSColor) -> NSImage {
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)

        image.lockFocus()

        // Draw a large circle for alert dialogs
        let rect = NSRect(x: 4, y: 4, width: 56, height: 56)
        let path = NSBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    func sendStatusUpdate(activity: String?, isActive: Bool) {
        Logger.shared.log("Sending status update: activity=\(activity ?? "none"), isActive=\(isActive)")
        
        // Send to HTTP endpoint
        guard let url = URL(string: "http://localhost:3000/api/data") else {
            Logger.shared.log("Invalid URL for HTTP endpoint")
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
            Logger.shared.log("Error serializing JSON: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.shared.log("Error sending HTTP status update: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                Logger.shared.log("HTTP status update sent. Response code: \(httpResponse.statusCode)")
            }
        }
        task.resume()
        
        // Write to Neon database
        writeToDatabase(activity: activity, isActive: isActive)
    }
    
    func writeToDatabase(activity: String?, isActive: Bool) {
        Logger.shared.log("Writing to database: activity=\(activity ?? "none"), isActive=\(isActive)")
        
        DispatchQueue.global(qos: .background).async {
            guard let neonPassword = ProcessInfo.processInfo.environment["NEON_PASSWORD"] else {
                Logger.shared.log("NEON_PASSWORD environment variable not set")
                return
            }
            
            let connectionString = "postgresql://neondb_owner:\(neonPassword)@ep-hidden-bird-aeebmse2-pooler.c-2.us-east-2.aws.neon.tech/neondb?sslmode=require"
            
            // First, create the table if it doesn't exist
            self.executeSQLQuery(
                query: "CREATE TABLE IF NOT EXISTS time_tracking (id SERIAL PRIMARY KEY, activity VARCHAR(50), is_active BOOLEAN, timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP)",
                connectionString: connectionString
            ) { success in
                if success {
                    Logger.shared.log("Table created/verified")
                    
                    // Then insert the record
                    let timestamp = ISO8601DateFormatter().string(from: Date())
                    let activityValue = activity ?? "none"
                    let insertSQL = "INSERT INTO time_tracking (activity, is_active, timestamp) VALUES ('\(activityValue)', \(isActive), '\(timestamp)')"
                    
                    self.executeSQLQuery(
                        query: insertSQL,
                        connectionString: connectionString
                    ) { success in
                        if success {
                            Logger.shared.log("Database write successful")
                        }
                    }
                } else {
                    Logger.shared.log("Failed to create table")
                }
            }
        }
    }
    
    func executeSQLQuery(query: String, connectionString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://ep-hidden-bird-aeebmse2-pooler.c-2.us-east-2.aws.neon.tech/sql") else {
            Logger.shared.log("Invalid database API URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(connectionString, forHTTPHeaderField: "Neon-Connection-String")
        
        let payload: [String: Any] = [
            "query": query
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            Logger.shared.log("Error serializing database request: \(error)")
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.shared.log("Database connection error: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    Logger.shared.log("Database query failed with status: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        Logger.shared.log("Response: \(responseString)")
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
        task.resume()
    }

    func startCheckInTimer() {
        Logger.shared.log("Starting 15-minute check-in timer")
        // Cancel existing timer if any
        checkInTimer?.invalidate()

        // Start new timer for 15 minutes (900 seconds)
        checkInTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.showCheckInPrompt()
        }
    }

    func stopCheckInTimer() {
        Logger.shared.log("Stopping check-in timer")
        checkInTimer?.invalidate()
        checkInTimer = nil
    }

    func showCheckInPrompt() {
        guard let currentActivity = timeTracker.currentActivity else { return }
        
        Logger.shared.log("Showing check-in prompt for activity: \(currentActivity.displayName)")

        let alert = NSAlert()
        alert.messageText = "Still working on \(currentActivity.displayName)?"
        alert.informativeText = "You've been tracking \(currentActivity.displayName) for 15 minutes. Would you like to continue or switch to a different activity?\n\nThis will auto-close in 60 seconds and stop tracking."
        alert.alertStyle = .informational
        alert.icon = createAlertIcon(color: currentActivity.color)
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Change Activity")
        alert.addButton(withTitle: "Stop Tracking")

        // Set up auto-dismiss timer (60 seconds)
        var timeoutTimer: Timer?
        var hasResponded = false

        DispatchQueue.main.async { [weak self] in
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
                if !hasResponded {
                    Logger.shared.log("Check-in prompt timed out")
                    NSApp.abortModal()
                }
            }

            let response = alert.runModal()
            hasResponded = true
            timeoutTimer?.invalidate()

            switch response {
            case .alertFirstButtonReturn:
                Logger.shared.log("User chose to continue current activity")
                // Continue - restart the timer
                self?.startCheckInTimer()

            case .alertSecondButtonReturn:
                Logger.shared.log("User chose to change activity")
                // Change Activity - show selection dialog
                self?.showActivitySelection()

            case .alertThirdButtonReturn, NSApplication.ModalResponse(rawValue: -1000):
                Logger.shared.log("User chose to stop tracking (or dialog closed)")
                // Stop tracking (also handles window close/timeout)
                self?.timeTracker.stopTracking()
                self?.sendStatusUpdate(activity: nil, isActive: false)
                self?.stopCheckInTimer()
                self?.updateMenu()

            default:
                Logger.shared.log("Check-in prompt cancelled or timed out")
                // Default to stopping tracking on timeout or cancel
                self?.timeTracker.stopTracking()
                self?.sendStatusUpdate(activity: nil, isActive: false)
                self?.stopCheckInTimer()
                self?.updateMenu()
            }
        }
    }

    func showActivitySelection() {
        Logger.shared.log("Showing activity selection dialog")
        
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
            Logger.shared.log("User selected new activity: \(selectedActivity.displayName)")
            timeTracker.startTracking(activity: selectedActivity)
            sendStatusUpdate(activity: selectedActivity.displayName, isActive: true)
            startCheckInTimer()
            updateMenu()
        } else {
            Logger.shared.log("Activity selection cancelled")
        }
    }

    @objc func notTrackingSelected() {
        Logger.shared.log("User selected 'Not tracking'")
        // Stop tracking if anything is active
        if timeTracker.currentActivity != nil {
            timeTracker.stopTracking()
            sendStatusUpdate(activity: nil, isActive: false)
            stopCheckInTimer()
            updateMenu()
        }
    }

    @objc func activitySelected(_ sender: NSMenuItem) {
        guard let activity = Activity(rawValue: sender.tag) else { return }

        if timeTracker.currentActivity == activity {
            Logger.shared.log("User deselected activity: \(activity.displayName)")
            // Deselect if clicking the same activity
            timeTracker.stopTracking()
            sendStatusUpdate(activity: nil, isActive: false)
            stopCheckInTimer()
        } else {
            Logger.shared.log("User selected activity: \(activity.displayName)")
            // Select new activity
            timeTracker.startTracking(activity: activity)
            sendStatusUpdate(activity: activity.displayName, isActive: true)
            startCheckInTimer()
        }

        updateMenu()
    }

    @objc func resetAllTimes() {
        Logger.shared.log("User requested to reset all times")
        
        let alert = NSAlert()
        alert.messageText = "Reset All Times?"
        alert.informativeText = "This will reset all tracked times to zero. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            Logger.shared.log("User confirmed reset all times")
            timeTracker.resetAllTimes()
            updateMenu()
        } else {
            Logger.shared.log("User cancelled reset all times")
        }
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.log("Application terminating")
        stopCheckInTimer()
        timeTracker.stopTracking()
    }
}
