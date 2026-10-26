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

                Text("Welcome to Orbit")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Make time for what matters.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)

                VStack(alignment: .leading) {
                    Text("Email").font(.headline)
                    TextField("you@example.com", text: $model.email)
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
                    if let message = model.emailValidationMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("emailValidationMessage")
                    }

                    Text("Password").font(.headline)
                        .padding(.top)
                    SecureField("Enter your password", text: $model.password)
                        .textContentType(.password)
                        .focused($passwordIsFocused)
                        .submitLabel(.go)
                        .onSubmit { requestsSignIn = true }
                        .accessibilityLabel("Password")
                        .accessibilityIdentifier("loginPasswordField")
                }
                .textFieldStyle(.roundedBorder)
                .disabled(model.isSigningIn || model.isSigningOut)

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
            guard requestsSignIn else { return }
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
