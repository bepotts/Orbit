import SwiftUI

/// Collects the backend user fields and confirms the password before registration.
struct SignUpView: View {
    /// Closes registration and returns to login.
    @Environment(\.dismiss) private var dismiss
    /// Registration state owned for the lifetime of this form.
    @State private var model: SignUpModel
    /// Opens the timer after a backend session has been established.
    let onSignedIn: () -> Void
    /// Triggers a cancellable submission tied to the view's lifetime.
    @State private var requestsSignUp = false

    /// Creates a registration form connected to the app's shared authentication state.
    ///
    /// - Parameters:
    ///   - loginModel: Login state that retains the authenticated session.
    ///   - onSignedIn: Action that presents the timer after successful authentication.
    init(loginModel: LoginModel, onSignedIn: @escaping () -> Void) {
        _model = State(initialValue: SignUpModel(loginModel: loginModel))
        self.onSignedIn = onSignedIn
    }

    /// Registration form or confirmation of the accepted request.
    var body: some View {
        NavigationStack {
            Form {
                if model.isSubmitting {
                    ProgressView("Creating account and signing in…")
                } else if model.isSubmitted {
                    Section {
                        Text(model
                            .errorMessage ??
                            "Registration submitted. If email confirmation is required, check your inbox.")
                        Button("Back to Sign In") { dismiss() }
                    }
                } else {
                    Section("Your name") {
                        TextField("First name", text: $model.firstName)
                            .textContentType(.givenName)
                            .accessibilityIdentifier("signUpFirstNameField")
                        TextField("Last name", text: $model.lastName)
                            .textContentType(.familyName)
                            .accessibilityIdentifier("signUpLastNameField")
                    }
                    .disabled(model.isSubmitting)
                    Section("Account details") {
                        TextField("Email", text: $model.email)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                        #if os(iOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        #endif
                            .accessibilityIdentifier("signUpEmailField")
                        if let message = model.emailValidationMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .accessibilityIdentifier("emailValidationMessage")
                        }
                        SecureField("Password", text: $model.password)
                            .textContentType(.newPassword)
                            .accessibilityIdentifier("signUpPasswordField")
                        SecureField("Confirm password", text: $model.passwordConfirmation)
                            .textContentType(.newPassword)
                            .accessibilityIdentifier("signUpConfirmPasswordField")
                        if !model.passwordConfirmation.isEmpty,
                           model.password != model.passwordConfirmation
                        {
                            Text("Passwords do not match.")
                                .foregroundStyle(.red)
                        }
                    }
                    .disabled(model.isSubmitting)
                    Section {
                        if let message = model.errorMessage {
                            Text(message)
                                .foregroundStyle(.red)
                                .accessibilityIdentifier("signUpErrorMessage")
                        }
                        Button("Create Account") { requestsSignUp = true }
                            .buttonStyle(.borderedProminent)
                            .tint(EmberColor.accentStart)
                            .disabled(!model.canSubmit || requestsSignUp)
                            .accessibilityIdentifier("createAccountButton")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Sign Up")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .disabled(model.isSubmitting)
                }
            }
            .interactiveDismissDisabled(model.isSubmitting)
            .task(id: requestsSignUp) {
                guard requestsSignUp else { return }
                await model.signUp()
                requestsSignUp = false
                if model.loginModel.session != nil, !Task.isCancelled {
                    dismiss()
                    onSignedIn()
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 520)
        #endif
    }
}
