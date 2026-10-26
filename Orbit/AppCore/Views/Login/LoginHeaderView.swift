import SwiftUI

/// Welcome heading and introduction for the login form.
struct LoginHeaderView: View {
    /// Branding and introductory text.
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.largeTitle)
            .foregroundStyle(EmberColor.gradient)
            .accessibilityHidden(true)

        Text("Welcome to Orbit")
            .font(.title)
            .bold()
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)

        Text("Make time for what matters.")
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.bottom)
    }
}
