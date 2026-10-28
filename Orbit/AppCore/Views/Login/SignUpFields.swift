import SwiftUI

/// Name and account fields for registration.
struct SignUpFields: View {
    /// Registration state edited by the form fields.
    @Bindable var model: SignUpModel

    /// Registration sections with inline validation.
    var body: some View {
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
    }
}

#Preview {
    @Previewable @State var model = SignUpModel()

    Form {
        SignUpFields(model: model)
    }
    .formStyle(.grouped)
}
