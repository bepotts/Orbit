import Foundation
import Observation

/// Owns credential entry, request state, and the current backend session.
@MainActor
@Observable
final class LoginModel {
    /// Email entered by the user.
    var email = ""
    /// Password held only until successful authentication.
    var password = ""
    /// Whether a request is currently in flight.
    private(set) var isSigningIn = false
    /// Whether the current session is being revoked.
    private(set) var isSigningOut = false
    /// Safe, user-facing explanation of the most recent failure.
    private(set) var errorMessage: String?
    /// Credentials returned by a successful login, held only in memory.
    private(set) var session: LoginSession?
    /// Injectable client factory, deferring configuration errors until submission.
    private let makeClient: @MainActor () throws -> BackendClient

    /// Whether the current email has valid syntax, refreshed as the field changes.
    var isEmailValid: Bool {
        EmailValidation.isValid(email)
    }

    /// Inline feedback while a nonempty email is incomplete or invalid.
    var emailValidationMessage: String? {
        email.isEmpty || isEmailValid ? nil : "Enter a valid email address."
    }

    /// Creates a login model using the configured backend or a test client.
    ///
    /// - Parameters:
    ///   - makeClient: Factory for the backend request client.
    init(makeClient: @escaping @MainActor () throws -> BackendClient = { try BackendClient() }) {
        self.makeClient = makeClient
    }

    /// Authenticates once, retaining the returned session only after validation.
    ///
    /// - Returns: Whether authentication succeeded.
    func signIn() async -> Bool {
        guard !isSigningIn, !isSigningOut else {
            return false
        }
        errorMessage = nil
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password."
            return false
        }
        guard isEmailValid else {
            errorMessage = "Enter a valid email address."
            return false
        }
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            let body = try JSONEncoder().encode(["email": email, "password": password])
            let data = try await makeClient().request(path: "api/v1/users/login", method: "POST", body: body)
            try Task.checkCancellation()
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(LoginSession.self, from: data)
            guard !result.accessToken.isEmpty, !result.refreshToken.isEmpty,
                  !result.userId.isEmpty, result.tokenType.lowercased() == "bearer",
                  result.expiresIn > 0
            else {
                throw BackendError.invalidResponse
            }
            session = result
            password = ""
            return true
        } catch is CancellationError {
            return false
        } catch let error as URLError where error.code == .cancelled {
            return false
        } catch let BackendError.httpStatus(status, _) {
            setErrorMessage(forHTTPStatus: status)
        } catch is URLError {
            errorMessage = "Unable to connect. Check your internet connection and try again."
        } catch {
            errorMessage = "Sign-in is temporarily unavailable. Please try again."
        }
        return false
    }

    /// Clears local credentials and asks the backend to revoke the current session.
    ///
    /// Local logout completes even when the backend is unreachable or the token has expired.
    func signOut() async {
        guard !isSigningOut, !isSigningIn else {
            return
        }
        let accessToken = session?.accessToken
        session = nil
        email = ""
        password = ""
        errorMessage = nil
        guard let accessToken else {
            return
        }
        isSigningOut = true
        defer { isSigningOut = false }
        do {
            _ = try await makeClient().request(
                path: "api/v1/sessions/current", method: "DELETE", accessToken: accessToken,
            )
        } catch BackendError.httpStatus(401, _) {
            // An expired or revoked session is already signed out.
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            errorMessage = "You are signed out on this device. We could not end the server session."
        }
    }

    /// Sets the user-facing message for an authentication HTTP failure.
    ///
    /// - Parameters:
    ///   - status: HTTP status returned by the backend.
    private func setErrorMessage(forHTTPStatus status: Int) {
        switch status {
        case 401:
            errorMessage = "Incorrect email or password. Please try again."
        case 422:
            errorMessage = "Enter a valid email address and password."
        case 429:
            errorMessage = "Too many sign-in attempts. Please try again later."
        default:
            errorMessage = "Sign-in is temporarily unavailable. Please try again."
        }
    }
}
