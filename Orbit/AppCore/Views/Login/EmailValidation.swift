import Foundation

/// Lightweight email syntax checks shared by authentication forms.
enum EmailValidation {
    /// Checks a trimmed address for a local part and a complete domain name.
    ///
    /// - Parameters:
    ///   - email: Current field contents, including any surrounding whitespace.
    /// - Returns: Whether the address has valid common email syntax; the backend remains authoritative.
    static func isValid(_ email: String) -> Bool {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard address.count <= 254,
              let separator = address.firstIndex(of: "@"),
              address[..<separator].count <= 64 else { return false }
        return address.range(
            of: #"\A[\p{L}\p{N}!#$%&'*+/=?^_`{|}~-]+(?:\.[\p{L}\p{N}!#$%&'*+/=?^_`{|}~-]+)*@"#
                +
                #"(?:[\p{L}\p{N}](?:[\p{L}\p{N}-]{0,61}[\p{L}\p{N}])?\.)+"#
                + #"[\p{L}](?:[\p{L}\p{N}-]{0,61}[\p{L}\p{N}])?\z"#,
            options: .regularExpression,
        ) != nil
    }
}
