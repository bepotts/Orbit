import Foundation

/// Sends HTTP requests to the backend independently view state
@MainActor
struct BackendClient {
    /// Backend root, including any deployment path prefix.
    let baseURL: URL
    /// Injectable transport for deterministic tests without a running server.
    private let transport: (URLRequest) async throws -> (Data, URLResponse)

    /// Creates a client using the backend URL from the selected build configuration.
    ///
    /// - Parameters:
    ///   - bundle: Bundle containing the BACKEND_BASE_URL setting.
    ///   - session: Session responsible for loading requests and propagating cancellation.
    /// - Throws: BackendError.invalidBaseURL when configuration is missing or malformed.
    init(bundle: Bundle = .main, session: URLSession = .shared) throws {
        guard let value = bundle.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
              let url = URL(string: value)
        else {
            throw BackendError.invalidBaseURL
        }
        try self.init(baseURL: url) { request in
            try await session.data(for: request)
        }
    }

    /// Creates a client with an explicit endpoint and transport.
    ///
    /// - Parameters:
    ///   - baseURL: HTTP or HTTPS root of the backend.
    ///   - transport: Async request loader, injectable for tests.
    /// - Throws: BackendError.invalidBaseURL for unsupported or ambiguous endpoints.
    init(
        baseURL: URL,
        transport: @escaping (URLRequest) async throws -> (Data, URLResponse)
    ) throws {
        guard ["http", "https"].contains(baseURL.scheme),
              let host = baseURL.host(), !host.isEmpty,
              baseURL.user() == nil, baseURL.password() == nil,
              baseURL.query() == nil, baseURL.fragment() == nil
        else {
            throw BackendError.invalidBaseURL
        }
        self.baseURL = baseURL
        self.transport = transport
    }

    /// Sends a JSON request and returns the successful response body, including empty bodies.
    ///
    /// - Parameters:
    ///   - path: Backend path relative to the configured root, such as `health`.
    ///   - method: HTTP method, defaulting to GET.
    ///   - body: Optional JSON data, produced with JSONEncoder by the caller.
    ///   - accessToken: Optional current user access token for protected endpoints.
    /// - Returns: Raw response data suitable for decoding with JSONDecoder.
    /// - Throws: Transport errors, cancellation, or BackendError for unsuccessful responses.
    func request(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        accessToken: String? = nil
    ) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await transport(request)
        guard let response = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw BackendError.httpStatus(response.statusCode, data)
        }
        return data
    }
}
