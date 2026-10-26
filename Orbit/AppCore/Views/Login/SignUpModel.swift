import Foundation
import Observation

/// Validates registration details and submits them to the backend.
@MainActor
@Observable
final class SignUpModel {
    /// Account owner's first name.
    var firstName = ""
    /// Account owner's last name.
    var lastName = ""
    /// Email address used for authentication.
    var email = ""
    /// New password, preserved exactly as entered.
    var password = ""
    /// Local confirmation, never sent to the server.
    var passwordConfirmation = ""
    /// Whether registration is in progress.
    private(set) var isSubmitting = false
    /// Safe explanation of a validation or backend failure.
    private(set) var errorMessage: String?
    /// Whether the backend accepted the registration request.
    private(set) var isSubmitted = false
    /// Shared authentication state that receives the newly created session.
    let loginModel: LoginModel
    /// Injectable backend factory for isolated tests.
    private let makeClient: @MainActor () throws -> BackendClient

    /// Whether the current email has valid syntax, refreshed as the field changes.
    var isEmailValid: Bool {
        EmailValidation.isValid(email)
    }

    /// Inline feedback while a nonempty email is incomplete or invalid.
    var emailValidationMessage: String? {
        email.isEmpty || isEmailValid ? nil : "Enter a valid email address."
    }

    /// Creates registration state with a configurable backend client.
    ///
    /// - Parameters:
    ///   - loginModel: Shared login state retained by the app after registration.
    ///   - makeClient: Factory used when submitting valid details.
    init(
        loginModel: LoginModel? = nil,
        makeClient: @escaping @MainActor () throws -> BackendClient = { try BackendClient() },
    ) {
        self.loginModel = loginModel ?? LoginModel(makeClient: makeClient)
        self.makeClient = makeClient
    }

    /// Reports whether all required fields are filled and the passwords match.
    var canSubmit: Bool {
        !isSubmitting && !isSubmitted
            && !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isEmailValid
            && !password.isEmpty && password == passwordConfirmation
    }

    /// Registers once, then signs in with the entered credentials and clears passwords.
    func signUp() async {
        guard !isSubmitting, !isSubmitted else {
            return
        }
        errorMessage = nil
        guard password == passwordConfirmation else {
            errorMessage = "Passwords do not match."
            return
        }
        guard isEmailValid else {
            errorMessage = "Enter a valid email address."
            return
        }
        guard canSubmit else {
            errorMessage = "Complete all fields to create your account."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let body = try registrationBody()
            _ = try await makeClient().request(path: "api/v1/users", method: "POST", body: body)
            try Task.checkCancellation()
            isSubmitted = true
            loginModel.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            loginModel.password = password
            password = ""
            passwordConfirmation = ""
            let signedIn = await loginModel.signIn()
            loginModel.password = ""
            if !signedIn, !Task.isCancelled {
                errorMessage = """
                Registration submitted, but automatic sign-in could not be completed. \
                If email confirmation is required, check your inbox, then sign in.
                """
            }
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch let BackendError.httpStatus(status, _) {
            setErrorMessage(forHTTPStatus: status)
        } catch is URLError {
            errorMessage = "Unable to connect. Check your internet connection and try again."
        } catch {
            errorMessage = "Sign-up is temporarily unavailable. Please try again."
        }
    }

    /// Sets the user-facing message for an authentication HTTP failure.
    ///
    /// - Parameters:
    ///   - status: HTTP status returned by the backend.
    private func setErrorMessage(forHTTPStatus status: Int) {
        switch status {
        case 400:
            errorMessage = "Registration could not be completed. Check your details and try a stronger password."
        case 422:
            errorMessage = "Check your name, email address, and password and try again."
        case 429:
            errorMessage = "Too many sign-up attempts. Please try again later."
        default:
            errorMessage = "Sign-up is temporarily unavailable. Please try again."
        }
    }

    /// Encodes registration details while preserving the entered password.
    ///
    /// - Returns: JSON data containing the backend registration fields.
    /// - Throws: An encoding error if the details cannot be serialized.
    private func registrationBody() throws -> Data {
        try JSONEncoder().encode([
            "first_name": firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            "last_name": lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
        ])
    }
}
