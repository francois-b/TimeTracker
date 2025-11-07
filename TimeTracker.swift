import Foundation
import Cocoa

enum Activity: Int, CaseIterable {
    case relax = 0
    case research = 1
    case work = 2
    case content = 3
    case jobSearch = 4

    var displayName: String {
        switch self {
        case .relax: return "Relax"
        case .research: return "Research"
        case .work: return "Work"
        case .content: return "Content"
        case .jobSearch: return "Job Search"
        }
    }

    var color: NSColor {
        switch self {
        case .relax: return NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0) // Green
        case .research: return NSColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0) // Blue
        case .work: return NSColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0) // Red
        case .content: return NSColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0) // Orange
        case .jobSearch: return NSColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1.0) // Purple
        }
    }

    var storageKey: String {
        return "time_\(displayName.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
}

class TimeTracker {
    private var totalTimes: [Activity: TimeInterval] = [:]
    private(set) var currentActivity: Activity?
    private var currentStartTime: Date?
    private var timer: Timer?

    private let defaults = UserDefaults.standard

    init() {
        Logger.shared.log("TimeTracker initializing")
        loadTimes()
    }

    func startTracking(activity: Activity) {
        Logger.shared.log("Starting tracking for activity: \(activity.displayName)")
        // Stop current tracking if any
        stopTracking()

        // Start new tracking
        currentActivity = activity
        currentStartTime = Date()

        // Update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
        }
    }

    func stopTracking() {
        guard let activity = currentActivity, let startTime = currentStartTime else {
            Logger.shared.log("stopTracking called but nothing was being tracked")
            return
        }

        // Calculate elapsed time and add to total
        let elapsed = Date().timeIntervalSince(startTime)
        totalTimes[activity, default: 0] += elapsed
        
        Logger.shared.log("Stopped tracking \(activity.displayName). Elapsed: \(elapsed) seconds")

        // Save to persistent storage
        saveTimes()

        // Clean up
        currentActivity = nil
        currentStartTime = nil
        timer?.invalidate()
        timer = nil
    }

    private func updateCurrentTime() {
        // This ensures the UI stays updated while tracking
        // The actual time is calculated when stopping
    }

    func getTotalTime(for activity: Activity) -> TimeInterval {
        var total = totalTimes[activity, default: 0]

        // Add current session time if this activity is active
        if currentActivity == activity, let startTime = currentStartTime {
            total += Date().timeIntervalSince(startTime)
        }

        return total
    }

    func resetAllTimes() {
        Logger.shared.log("Resetting all times")
        stopTracking()
        totalTimes.removeAll()
        saveTimes()
    }

    // MARK: - Persistence

    private func loadTimes() {
        Logger.shared.log("Loading times from UserDefaults")
        for activity in Activity.allCases {
            let time = defaults.double(forKey: activity.storageKey)
            if time > 0 {
                totalTimes[activity] = time
                Logger.shared.log("Loaded \(activity.displayName): \(time) seconds")
            }
        }
    }

    private func saveTimes() {
        Logger.shared.log("Saving times to UserDefaults")
        for activity in Activity.allCases {
            let time = totalTimes[activity, default: 0]
            defaults.set(time, forKey: activity.storageKey)
        }
    }
}
