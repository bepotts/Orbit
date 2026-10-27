import Foundation

/// Failures configuring or communicating with the Orbit HTTP API.
enum BackendError: Error, Equatable {
    /// The bundle contains no valid backend HTTP or HTTPS URL.
    case invalidBaseURL
    /// URL loading returned a response that was not HTTP.
    case invalidResponse
    /// The backend rejected the request; retain its response for caller-specific decoding.
    case httpStatus(Int, Data)
}
