import SwiftUI

/// Presents the Ember welcome screen and login before the shared timer.
struct AppRootView: View {
    /// Whether this window has finished its initial welcome screen.
    @State private var hasFinishedLanding = false
    /// Whether this window has continued past the placeholder login page.
    @State private var showsTimer = false

    /// The welcome screen, login page, or platform's existing timer surface.
    var body: some View {
        Group {
            if !hasFinishedLanding {
                LandingPageView()
                    #if os(macOS)
                    .frame(width: 360, height: 520)
                    #endif
                    .task {
                        await finishLanding()
                    }
            } else if showsTimer {
                #if os(macOS)
                MacTimerView()
                #else
                IOSTimerView()
                #endif
            } else {
                LoginView {
                    showsTimer = true
                }
                #if os(macOS)
                .frame(width: 360, height: 520)
                #endif
            }
        }
    }

    /// Advances to sign-in after three seconds unless the welcome screen disappears.
    private func finishLanding() async {
        do {
            try await Task.sleep(for: .seconds(3))
            try Task.checkCancellation()
            hasFinishedLanding = true
        } catch {
            // Keep the welcome state when SwiftUI cancels its presentation task.
        }
    }
}
