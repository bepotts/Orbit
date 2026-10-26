import Fakery
import Foundation
@testable import Orbit
import Testing

/// Verifies startup health retries without contacting a real server or waiting.
@MainActor
struct BackendHealthCheckTests {
    /// Verifies both network and HTTP failures retry, then stop on success.
    @Test func `retries until online`() async throws {
        let url = try #require(URL(string: "https://\(Faker().internet.domainName())"))
        var attempts = 0
        var delays = 0
        let client = try BackendClient(baseURL: url) { request in
            #expect(request.url == url.appending(path: "health"))
            #expect(request.httpMethod == "GET")
            attempts += 1
            if attempts == 1 {
                throw URLError(.cannotConnectToHost)
            }
            let response = try #require(HTTPURLResponse(
                url: url, statusCode: attempts == 2 ? 503 : 200,
                httpVersion: nil, headerFields: nil,
            ))
            return (Data(), response)
        }
        let check = BackendHealthCheck(client: client, retryDelay: { delays += 1 })
        await check.waitUntilOnline()
        #expect(attempts == 3)
        #expect(delays == 2)
    }

    /// Verifies cancellation during the retry delay stops further requests.
    @Test func `stops when delay is cancelled`() async throws {
        let url = try #require(URL(string: "https://\(Faker().internet.domainName())"))
        var attempts = 0
        let client = try BackendClient(baseURL: url) { _ in
            attempts += 1
            throw URLError(.cannotConnectToHost)
        }
        let check = BackendHealthCheck(client: client, retryDelay: { throw CancellationError() })
        await check.waitUntilOnline()
        #expect(attempts == 1)
    }
}
