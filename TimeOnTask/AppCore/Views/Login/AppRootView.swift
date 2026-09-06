import SwiftUI

/// Presents the login setup before allowing access to the shared timer.
struct AppRootView: View {
    /// The login page or the platform's existing timer surface.
    var body: some View {
        Group {
            if showsTimer {
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

    /// Whether this window has continued past the placeholder login page.
    @State private var showsTimer = false
}
