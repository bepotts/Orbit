import Foundation
@testable import Orbit
import Testing

/// Verifies local logout and backend session revocation.
@MainActor
struct LogoutTests {
    /// Clears credentials and sends the authenticated logout request, including expired sessions.
    ///
    /// - Parameters:
    ///   - status: Backend logout result to simulate.
    @Test(arguments: [204, 401, 503])
    func `signs out`(status: Int) async throws {
        let url = try #require(URL(string: "https://example.com"))
        var logoutRequests = 0
        let client = try BackendClient(baseURL: url) { request in
            if request.httpMethod == "DELETE" {
                logoutRequests += 1
                #expect(request.url?.path() == "/api/v1/sessions/current")
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access")
                #expect(request.httpBody == nil)
                let response = try #require(HTTPURLResponse(
                    url: url,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil,
                ))
                return (Data(), response)
            }
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
        model.email = "user@example.com"
        model.password = "password"
        #expect(await model.signIn())
        await model.signOut()
        #expect(model.session == nil)
        #expect(model.email.isEmpty)
        #expect(model.password.isEmpty)
        #expect(!model.isSigningOut)
        #expect((model.errorMessage != nil) == (status == 503))
        await model.signOut()
        #expect(logoutRequests == 1)
    }

    /// Leaves no credentials when the logout transport is offline.
    @Test func `offline logout`() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let client = try BackendClient(baseURL: url) { request in
            if request.httpMethod == "DELETE" {
                throw URLError(.notConnectedToInternet)
            }
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
        model.email = "user@example.com"
        model.password = "password"
        #expect(await model.signIn())
        await model.signOut()
        #expect(model.session == nil)
        #expect(model.errorMessage != nil)
        #expect(!model.isSigningOut)
    }

    /// Guest navigation clears entered credentials without making a backend request.
    @Test func `guest logout`() async {
        let model = LoginModel {
            Issue.record("Guest logout must not contact the backend.")
            throw BackendError.invalidBaseURL
        }
        model.email = "user@example.com"
        model.password = "password"
        await model.signOut()
        #expect(model.session == nil)
        #expect(model.email.isEmpty)
        #expect(model.password.isEmpty)
    }
}
