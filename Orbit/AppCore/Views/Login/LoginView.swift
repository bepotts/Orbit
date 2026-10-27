import SwiftUI

/// Email and password entry backed by the Orbit authentication API.
struct LoginView: View {
    /// Opens the timer after authentication or an explicit guest choice.
    let onContinue: () -> Void
    /// Login state owned by the root view so the session survives navigation.
    @Bindable var model: LoginModel
    /// Whether the view should run a sign-in request.
    @State private var requestsSignIn = false
    /// Whether the registration form is presented.
    @State private var showsSignUp = false

    /// Login form shared by the desktop and mobile apps.
    var body: some View {
        ScrollView {
            VStack {
                LoginHeaderView()

                LoginCredentialFields(model: model, requestsSignIn: $requestsSignIn)

                Button {
                    requestsSignIn = true
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
                .disabled(model.isSigningIn || model.isSigningOut || !model.isEmailValid)

                if model.isSigningOut {
                    ProgressView("Signing out…")
                }
                if model.isSigningIn {
                    ProgressView("Signing in…")
                }
                if let message = model.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("loginErrorMessage")
                }

                Button("Sign Up") { showsSignUp = true }
                    .disabled(model.isSigningIn || model.isSigningOut || requestsSignIn)
                    .accessibilityIdentifier("signUpButton")

                Button("Continue without signing in", action: onContinue)
                    .buttonStyle(.borderless)
                    .padding(.top)
                    .accessibilityIdentifier("continueWithoutSignInButton")
                    .disabled(model.isSigningIn || model.isSigningOut)
            }
            .padding()
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center)
        .sheet(isPresented: $showsSignUp) {
            SignUpView(loginModel: model, onSignedIn: onContinue)
        }
        .task(id: requestsSignIn) {
            guard requestsSignIn else {
                return
            }
            if await model.signIn() {
                onContinue()
            }
            requestsSignIn = false
        }
    }
}

#Preview {
    LoginView(onContinue: {}, model: LoginModel())
}
