import Fakery
import Foundation
@testable import Orbit
import Testing

/// Verifies request construction and response handling without external services.
@MainActor
struct BackendClientTests {
    /// Verifies JSON and authorization reach the intended backend path.
    @Test func sendsJSONWithBearerToken() async throws {
        let faker = Faker()
        let url = try #require(URL(string: "https://\(faker.internet.domainName())/backend"))
        let path = "api/v1/\(faker.lorem.word())"
        let accessToken = faker.internet.password()
        let body = try JSONEncoder().encode(["message": faker.lorem.sentence()])
        let client = try BackendClient(baseURL: url) { request in
            #expect(request.url?.absoluteString == "\(url.absoluteString)/\(path)")
            #expect(request.httpMethod == "POST")
            #expect(request.httpBody == body)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(accessToken)")
            let response = try #require(HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil))
            return (body, response)
        }
        let result = try await client.request(
            path: path, method: "POST", body: body, accessToken: accessToken
        )
        #expect(result == body)
    }

    /// Verifies failed HTTP responses retain their status and validation details.
    @Test func preservesHTTPFailure() async throws {
        let url = try #require(URL(string: "https://\(Faker().internet.domainName())"))
        let body = try JSONEncoder().encode(["detail": Faker().lorem.sentence()])
        let client = try BackendClient(baseURL: url) { _ in
            let response = try #require(HTTPURLResponse(url: url, statusCode: 422, httpVersion: nil, headerFields: nil))
            return (body, response)
        }
        await #expect(throws: BackendError.httpStatus(422, body)) {
            try await client.request(path: Faker().lorem.word())
        }
    }

    /// Verifies invalid configuration is rejected before any network call.
    ///
    /// - Parameters:
    ///   - value: Unsupported or ambiguous backend URL to reject.
    @Test(arguments: ["file:///tmp/backend", "https://example.com?query=value", "https://user:password@example.com"])
    func rejectsInvalidBaseURL(value: String) throws {
        let url = try #require(URL(string: value))
        #expect(throws: BackendError.invalidBaseURL) {
            try BackendClient(baseURL: url) { _ in
                Issue.record("Invalid configuration must not reach the transport.")
                throw URLError(.badURL)
            }
        }
    }

    /// Verifies empty successful responses work for DELETE and other no-content endpoints.
    @Test func acceptsNoContent() async throws {
        let url = try #require(URL(string: "https://\(Faker().internet.domainName())"))
        let client = try BackendClient(baseURL: url) { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
            let response = try #require(HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil))
            return (Data(), response)
        }
        let result = try await client.request(path: Faker().lorem.word(), method: "DELETE")
        #expect(result.isEmpty)
    }

    /// Verifies transport failures, including cancellation, reach the caller unchanged.
    ///
    /// - Parameters:
    ///   - code: URL loading error that the transport should propagate.
    @Test(arguments: [URLError.Code.cancelled, .notConnectedToInternet, .timedOut])
    func propagatesTransportErrors(code: URLError.Code) async throws {
        let url = try #require(URL(string: "https://\(Faker().internet.domainName())"))
        let client = try BackendClient(baseURL: url) { _ in
            throw URLError(code)
        }
        await #expect(throws: URLError(code)) {
            try await client.request(path: Faker().lorem.word())
        }
    }
}
