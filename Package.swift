// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TimeTracker",
    platforms: [
        .macOS(.v11)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TimeTracker",
            dependencies: [],
            path: ".",
            sources: ["main.swift", "TimeTrackerApp.swift", "TimeTracker.swift"]
        )
    ]
)
