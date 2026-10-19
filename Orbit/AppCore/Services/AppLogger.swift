//
//  AppLogger.swift
//  Orbit
//

import Foundation
import os

extension Logger {
    /// App-wide subsystem used to group logs from Orbit.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "pottsProjects.TimeOnTask"

    /// Logger for SwiftUI view lifecycle and user interaction events.
    static let views = Logger(subsystem: subsystem, category: "Views")

    /// Logger for service side effects and system integrations.
    static let services = Logger(subsystem: subsystem, category: "Services")
}
