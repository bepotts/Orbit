import SwiftUI

/// Presents the Ember welcome screen and login before the shared timer.
struct AppRootView: View {
    /// Whether this window has finished its initial welcome screen.
    @State private var hasFinishedLanding = false
    /// Whether this window has continued past the login page.
    @State private var showsTimer = false

    /// Triggers logout in a task owned by this root view.
    @State private var requestsSignOut = false

    /// Authentication state retained when the timer is presented.
    @State private var loginModel = LoginModel()

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
                Group {
                    #if os(macOS)
                        MacTimerView()
                    #else
                        IOSTimerView()
                    #endif
                }
                .safeAreaInset(edge: .top) {
                    HStack {
                        Spacer()
                        Button(loginModel.session == nil ? "Back to Sign In" : "Log Out") {
                            requestsSignOut = true
                        }
                        .accessibilityIdentifier("logoutButton")
                        .disabled(requestsSignOut)
                    }
                    .padding()
                }
            } else {
                LoginView(onContinue: {
                    showsTimer = true
                }, model: loginModel)
                #if os(macOS)
                    .frame(width: 360, height: 520)
                #endif
            }
        }
        .task(id: requestsSignOut) {
            guard requestsSignOut else {
                return
            }
            showsTimer = false
            await loginModel.signOut()
            requestsSignOut = false
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
