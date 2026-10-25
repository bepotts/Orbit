//
//  OrbitApp.swift
//  Orbit
//
//  Created by Brandon Potts on 8/16/26.
//

import OSLog
import SwiftUI

/// Main entry point for the Orbit app.
@main
struct OrbitApp: App {
    /// Shared timer state that is injected into both the main window and menu bar UI.
    @State private var engine = TimerEngine()

    /// Startup check owned for the application lifetime, independent of scene visibility.
    private let backendHealthTask: Task<Void, Never>

    /// Initializes shared services and checks backend availability without delaying the UI.
    init() {
        _ = SupabaseService.client
        backendHealthTask = Task {
            do {
                let client = try BackendClient()
                await BackendHealthCheck(client: client).waitUntilOnline()
            } catch {
                Logger.services.error("Cannot check backend health: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Defines the app's visible scenes for each supported platform.
    var body: some Scene {
        #if os(macOS)
            WindowGroup {
                AppRootView()
                    .environment(engine)
            }
            .windowResizability(.contentSize)
            .defaultSize(width: 360, height: 440)

            MenuBarExtra {
                MenuBarContentView()
                    .environment(engine)
            } label: {
                MenuBarLabel()
                    .environment(engine)
            }
            .menuBarExtraStyle(.window)
        #else
            WindowGroup {
                AppRootView()
                    .environment(engine)
            }
        #endif
    }
}
