import Foundation
@testable import Orbit
import Testing

/// Verifies registration validation and the backend request contract.
@MainActor
struct SignUpModelTests {
    /// Checks only backend user fields are sent and passwords retain whitespace.
    @Test func `submits user fields`() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { request in
            if request.url?.path() == "/api/v1/users/login" {
                let data = try #require(request.httpBody)
                let credentials = try JSONDecoder().decode([String: String].self, from: data)
                #expect(credentials == ["email": "jane@example.com", "password": " secret "])
                let response = try #require(HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil,
                ))
                return (
                    Data(
                        #"{"access_token":"access","refresh_token":"refresh","token_type":"bearer","expires_in":3600,"expires_at":null,"user_id":"user"}"#
                            .utf8,
                    ),
                    response,
                )
            }
            #expect(request.url?.path() == "/api/v1/users")
            #expect(request.httpMethod == "POST")
            let data = try #require(request.httpBody)
            let body = try JSONDecoder().decode([String: String].self, from: data)
            #expect(body == [
                "first_name": "Jane",
                "last_name": "Doe",
                "email": "jane@example.com",
                "password": " secret ",
            ])
            let response = try #require(HTTPURLResponse(url: url, statusCode: 202, httpVersion: nil, headerFields: nil))
            return (Data(#"{"message":"Registration submitted."}"#.utf8), response)
        }
        let model = populatedModel(client: client)
        await model.signUp()
        #expect(model.isSubmitted)
        #expect(model.loginModel.session?.accessToken == "access")
        #expect(model.loginModel.password.isEmpty)
        #expect(model.password.isEmpty)
        #expect(model.passwordConfirmation.isEmpty)
        #expect(!model.isSubmitting)
        #expect(model.errorMessage == nil)
        #expect(!model.canSubmit)
    }

    /// Keeps registration accepted when a confirmation requirement prevents sign-in.
    @Test func `handles automatic sign in failure`() async throws {
        let url = try #require(URL(string: "https://example.com"))
        var paths: [String] = []
        let client = try BackendClient(baseURL: url) { request in
            let path = try #require(request.url?.path())
            paths.append(path)
            let status = path == "/api/v1/users" ? 202 : 401
            let response = try #require(HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil,
            ))
            return (Data(), response)
        }
        let model = populatedModel(client: client)
        await model.signUp()
        #expect(model.isSubmitted)
        #expect(model.loginModel.session == nil)
        #expect(model.errorMessage != nil)
        #expect(model.password.isEmpty)
        #expect(model.loginModel.password.isEmpty)
        await model.signUp()
        #expect(paths == ["/api/v1/users", "/api/v1/users/login"])
    }

    /// Checks invalid fields never reach the transport, even on direct submission.
    ///
    /// - Parameters:
    ///   - mismatched: Whether to reject mismatched passwords instead of a missing name.
    @Test(arguments: [true, false])
    func `blocks invalid fields`(mismatched: Bool) async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { _ in
            Issue.record("Invalid registration must not reach the backend.")
            throw URLError(.badURL)
        }
        let model = populatedModel(client: client)
        if mismatched {
            model.passwordConfirmation = "different"
        } else {
            model.firstName = "  "
        }
        #expect(!model.canSubmit)
        await model.signUp()
        #expect(!model.isSubmitted)
        #expect(model.errorMessage != nil)
    }

    /// Checks rejected registrations remain editable and can be retried.
    ///
    /// - Parameters:
    ///   - status: Backend validation, throttling, or service failure status.
    @Test(arguments: [400, 422, 429, 503])
    func `handles backend failures`(status: Int) async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { _ in
            let response = try #require(HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil,
            ))
            return (Data(), response)
        }
        let model = populatedModel(client: client)
        await model.signUp()
        #expect(!model.isSubmitted)
        #expect(model.errorMessage != nil)
        #expect(model.canSubmit)
        #expect(model.password == " secret ")
    }

    /// Checks transport errors and cancellation reset the loading state.
    ///
    /// - Parameters:
    ///   - code: Network failure to simulate.
    @Test(arguments: [URLError.Code.notConnectedToInternet, .cancelled])
    func `handles transport failure`(code: URLError.Code) async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { _ in throw URLError(code) }
        let model = populatedModel(client: client)
        await model.signUp()
        #expect(!model.isSubmitted)
        #expect(!model.isSubmitting)
        #expect((model.errorMessage == nil) == (code == .cancelled))
    }

    /// Creates a complete form for registration tests.
    ///
    /// - Parameters:
    ///   - client: Test transport used by the form.
    /// - Returns: Registration state with matching passwords and padded profile fields.
    private func populatedModel(client: BackendClient) -> SignUpModel {
        let model = SignUpModel(makeClient: { client })
        model.firstName = " Jane "
        model.lastName = " Doe "
        model.email = " jane@example.com "
        model.password = " secret "
        model.passwordConfirmation = " secret "
        return model
    }
}
