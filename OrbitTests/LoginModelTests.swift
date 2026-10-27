import Foundation
@testable import Orbit
import Testing

/// Exercises authentication without contacting a live backend.
@MainActor
struct LoginModelTests {
    /// Checks the request contract, credential whitespace, and session retention.
    @Test func `successful login`() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { request in
            #expect(request.url?.path() == "/api/v1/users/login")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.httpBody)
            let credentials = try JSONDecoder().decode([String: String].self, from: body)
            #expect(credentials == ["email": "person@example.com", "password": " secret "])
            let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
            return (
                Data(
                    (#"{"access_token":"access","refresh_token":"refresh","token_type":"bearer""#
                        + #","expires_in":3600,"expires_at":null,"user_id":"user"}"#)
                        .utf8,
                ),
                response,
            )
        }
        let model = LoginModel { client }
        model.email = " person@example.com "
        model.password = " secret "
        let success = await model.signIn()
        #expect(success)
        #expect(model.session?.accessToken == "access")
        #expect(model.session?.userId == "user")
        #expect(model.password.isEmpty)
        #expect(!model.isSigningIn)
        #expect(model.errorMessage == nil)
    }

    /// Checks safe error messages and preservation of the login screen on failures.
    ///
    /// - Parameters:
    ///   - status: Backend rejection status.
    @Test(arguments: [401, 422, 429, 503])
    func `rejected login`(status: Int) async throws {
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
        let model = LoginModel { client }
        model.email = "person@example.com"
        model.password = "wrong"
        #expect(await model.signIn() == false)
        #expect(model.session == nil)
        #expect(model.errorMessage != nil)
        if status == 401 {
            #expect(model.errorMessage == "Incorrect email or password. Please try again.")
        }
        #expect(!model.isSigningIn)
    }

    /// Rejects successful HTTP responses that do not contain usable credentials.
    @Test func `malformed success`() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { _ in
            let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
            return (Data("{}".utf8), response)
        }
        let model = LoginModel { client }
        model.email = "person@example.com"
        model.password = "password"
        #expect(await model.signIn() == false)
        #expect(model.session == nil)
        #expect(model.errorMessage != nil)
    }

    /// Checks empty credentials are rejected without constructing a request.
    @Test func `empty credentials`() async {
        let model = LoginModel {
            Issue.record("Empty credentials must not reach the backend.")
            throw BackendError.invalidBaseURL
        }
        #expect(await model.signIn() == false)
        #expect(model.errorMessage == "Enter your email and password.")
    }

    /// Checks network failure and cancellation leave no authenticated session.
    ///
    /// - Parameters:
    ///   - code: Transport failure to simulate.
    @Test(arguments: [URLError.Code.notConnectedToInternet, .cancelled])
    func `transport failure`(code: URLError.Code) async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { _ in throw URLError(code) }
        let model = LoginModel { client }
        model.email = "person@example.com"
        model.password = "password"
        #expect(await model.signIn() == false)
        #expect(model.session == nil)
        #expect(!model.isSigningIn)
        #expect((model.errorMessage == nil) == (code == .cancelled))
    }
}
