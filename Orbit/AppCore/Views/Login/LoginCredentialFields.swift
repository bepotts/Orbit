import SwiftUI

/// Credential fields shared by the login form.
struct LoginCredentialFields: View {
    /// Authentication state edited by the fields.
    @Bindable var model: LoginModel
    /// Submission trigger owned by the login view.
    @Binding var requestsSignIn: Bool
    /// Keyboard focus for advancing from email to password.
    @FocusState private var passwordIsFocused: Bool

    /// Email and password inputs with inline validation.
    var body: some View {
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
    }
}

#Preview {
    @Previewable @State var model = LoginModel()
    @Previewable @State var requestsSignIn = false

    LoginCredentialFields(model: model, requestsSignIn: $requestsSignIn)
        .padding()
}
