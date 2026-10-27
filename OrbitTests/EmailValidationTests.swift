@testable import Orbit
import Testing

/// Verifies live email feedback and prevents requests for invalid addresses.
@MainActor
struct EmailValidationTests {
    /// Accepts common email formats and surrounding pasted whitespace.
    ///
    /// - Parameters:
    ///   - email: Address to validate.
    @Test(arguments: ["user@example.com", "first.last+tag@sub.example.co.uk", " user@example.com ", "person@例子.公司"])
    func `accepts valid email`(email: String) {
        #expect(EmailValidation.isValid(email))
    }

    /// Rejects incomplete addresses, repeated separators, and invalid domain labels.
    ///
    /// - Parameters:
    ///   - email: Malformed address to reject.
    @Test(arguments: [
        "",
        "user",
        "user@",
        "user@example",
        "@example.com",
        "user@@example.com",
        "a..b@example.com",
        ".user@example.com",
        "user@-example.com",
        "user@example..com",
        "user name@example.com"
    ])
    func `rejects invalid email`(email: String) {
        #expect(!EmailValidation.isValid(email))
    }

    /// Checks feedback disappears on valid input and returns after an invalid edit.
    @Test func `updates feedback while typing`() {
        let login = LoginModel()
        let signUp = SignUpModel()
        #expect(login.emailValidationMessage == nil)
        #expect(signUp.emailValidationMessage == nil)
        for character in "user@example" {
            login.email.append(character)
            signUp.email.append(character)
            #expect(login.emailValidationMessage != nil)
            #expect(signUp.emailValidationMessage != nil)
        }
        login.email += ".com"
        signUp.email += ".com"
        #expect(login.emailValidationMessage == nil)
        #expect(signUp.emailValidationMessage == nil)
        login.email += "@"
        signUp.email += "@"
        #expect(login.emailValidationMessage != nil)
        #expect(signUp.emailValidationMessage != nil)
    }

    /// Checks invalid email cannot bypass validation through direct submission.
    @Test func `blocks invalid email requests`() async {
        let login = LoginModel {
            Issue.record("Invalid email must not reach the backend.")
            throw BackendError.invalidBaseURL
        }
        login.email = "invalid"
        login.password = "password"
        #expect(await login.signIn() == false)
        let signUp = SignUpModel {
            Issue.record("Invalid email must not reach the backend.")
            throw BackendError.invalidBaseURL
        }
        signUp.firstName = "Jane"
        signUp.lastName = "Doe"
        signUp.email = "invalid"
        signUp.password = "password"
        signUp.passwordConfirmation = "password"
        #expect(!signUp.canSubmit)
        await signUp.signUp()
        #expect(!signUp.isSubmitted)
    }
}
