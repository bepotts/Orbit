import Foundation
import OSLog

/// Checks backend availability at startup until the server responds successfully.
@MainActor
struct BackendHealthCheck {
    /// Client used to send the health request.
    let client: BackendClient
    /// Delay between failed requests, injectable for deterministic tests.
    var retryDelay: () async throws -> Void = { try await Task.sleep(for: .seconds(5)) }

    /// Requests backend health until successful or cancelled, logging each failure.
    func waitUntilOnline() async {
        while !Task.isCancelled {
            do {
                _ = try await client.request(path: "health")
                Logger.services.info("Backend is online.")
                return
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                Logger.services.error("Backend is unavailable: \(error.localizedDescription, privacy: .public). Retrying in five seconds.")
            }

            do {
                try await retryDelay()
            } catch {
                return
            }
        }
    }
}
