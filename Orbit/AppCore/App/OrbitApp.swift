//
//  OrbitApp.swift
//  Orbit
//
//  Created by Brandon Potts on 8/16/26.
//

import SwiftUI

/// Main entry point for the Orbit app.
@main
struct OrbitApp: App {
    /// Initializes the shared backend client when the app starts.
    init() {
        _ = SupabaseService.client
    }

    /// Shared timer state that is injected into both the main window and menu bar UI.
    @State private var engine = TimerEngine()

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
