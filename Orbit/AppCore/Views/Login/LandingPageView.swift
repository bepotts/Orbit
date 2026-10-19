import SwiftUI

/// A branded welcome screen shown before sign-in.
struct LandingPageView: View {
    /// The Ember name and flame in the app's shared accent colors.
    var body: some View {
        VStack {
            Image(systemName: "flame.fill")
                .font(.largeTitle)
                .foregroundStyle(EmberColor.gradient)
                .accessibilityHidden(true)

            Text("Orbit")
                .font(.largeTitle).bold()
                .accessibilityAddTraits(.isHeader)

            Text("Make time for what matters.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("emberLandingPage")
    }
}

#Preview {
    LandingPageView()
}
