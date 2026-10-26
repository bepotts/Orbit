/// Credentials returned by the backend, retained only for the current app session.
struct LoginSession: Decodable {
    /// Bearer credential for authenticated backend requests.
    let accessToken: String
    /// Credential used to renew the session.
    let refreshToken: String
    /// Authentication scheme returned by the server.
    let tokenType: String
    /// Session lifetime in seconds.
    let expiresIn: Int
    /// Optional expiration time as Unix seconds.
    let expiresAt: Int?
    /// Identifier of the authenticated account.
    let userId: String
}
