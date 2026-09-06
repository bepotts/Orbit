import SwiftUI

/// Email and password entry while authentication is being prepared.
struct LoginView: View {
    /// Opens the timer without creating an authenticated session.
    let onContinue: () -> Void
    /// Email entered for the future authentication flow, held only in memory.
    @State private var email = ""
    /// Password entered for the future authentication flow, held only in memory.
    @State private var password = ""
    /// Whether the placeholder sign-in explanation is presented.
    @State private var showsPlaceholder = false
    /// Keyboard focus for advancing from email to password.
    @FocusState private var passwordIsFocused: Bool

    /// Login form shared by the desktop and mobile apps.
    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "flame.fill")
                    .font(.largeTitle)
                    .foregroundStyle(EmberColor.gradient)
                    .accessibilityHidden(true)

                Text("Welcome to Ember")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Make time for what matters.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)

                VStack(alignment: .leading) {
                    Text("Email").font(.headline)
                    TextField("you@example.com", text: $email)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .submitLabel(.next)
                        .onSubmit { passwordIsFocused = true }
                        .accessibilityLabel("Email")
                        .accessibilityIdentifier("loginEmailField")

                    Text("Password").font(.headline)
                        .padding(.top)
                    SecureField("Enter your password", text: $password)
                        .textContentType(.password)
                        .focused($passwordIsFocused)
                        .submitLabel(.go)
                        .onSubmit { showsPlaceholder = true }
                        .accessibilityLabel("Password")
                        .accessibilityIdentifier("loginPasswordField")
                }
                .textFieldStyle(.roundedBorder)

                Button {
                    showsPlaceholder = true
                } label: {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(EmberColor.accentStart)
                .foregroundStyle(.black)
                .controlSize(.large)
                .padding(.top)
                .accessibilityIdentifier("signInButton")

                Text("Sign-in is coming soon. You can use the timer now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Continue without signing in", action: onContinue)
                    .buttonStyle(.borderless)
                    .padding(.top)
                    .accessibilityIdentifier("continueWithoutSignInButton")
            }
            .padding()
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center)
        .alert("Sign-in is coming soon", isPresented: $showsPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Authentication isn’t connected yet. Your email and password have not been sent or saved.")
        }
    }

}

#Preview {
    LoginView(onContinue: {})
}
