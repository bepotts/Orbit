//
//  EmberStyle.swift
//  Orbit
//

import SwiftUI

extension Color {
    /// Creates a SwiftUI color from a six-character RGB hex string.
    ///
    /// - Parameters:
    ///   - hex: The RGB hex value, with or without a leading number sign.
    init(hex: String) {
        // Hex string normalized so Scanner can read it with or without a leading #.
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacing("#", with: "")
        // Numeric RGB value parsed from the normalized hex string.
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >> 8) / 255,
            blue: Double(rgb & 0x0000FF) / 255,
        )
    }
}

/// Shared colors and gradients used by the Ember visual style.
enum EmberColor {
    /// Warm starting color used for filled controls and gradients.
    static let accentStart = Color(hex: "F2A65A")
    /// Deeper ending color used to complete the ember gradient.
    static let accentEnd = Color(hex: "C8672B")
    /// Shared gradient used for the timer ring and primary circular button.
    static let gradient = LinearGradient(
        colors: [accentStart, accentEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
    )
}

struct EmberRoundButtonStyle: ButtonStyle {
    /// Whether the circular button should use the filled accent treatment.
    var filled: Bool

    /// Builds the rounded button style body.
    ///
    /// - Parameters:
    ///   - configuration: The current button style configuration supplied by SwiftUI.
    /// - Returns: The styled button body.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 44, height: 44)
            .background {
                Circle().fill(filled ? AnyShapeStyle(EmberColor.gradient) : AnyShapeStyle(Color.primary.opacity(0.06)))
            }
            .overlay {
                Circle().stroke(Color.primary.opacity(filled ? 0 : 0.14), lineWidth: 1)
            }
            .foregroundStyle(filled ? Color.black.opacity(0.82) : Color.primary)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct EmberPillButtonStyle: ButtonStyle {
    /// Whether the preset pill represents the currently selected duration.
    var active: Bool

    /// Builds the preset pill button style body.
    ///
    /// - Parameters:
    ///   - configuration: The current button style configuration supplied by SwiftUI.
    /// - Returns: The styled button body.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: active ? .semibold : .regular, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule().fill(active ? AnyShapeStyle(EmberColor.accentStart) : AnyShapeStyle(Color.clear))
            }
            .overlay {
                Capsule().stroke(Color.primary.opacity(active ? 0 : 0.16), lineWidth: 1)
            }
            .foregroundStyle(active ? Color.black.opacity(0.82) : Color.secondary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct EmberTextButtonStyle: ButtonStyle {
    /// Builds the text button style body.
    ///
    /// - Parameters:
    ///   - configuration: The current button style configuration supplied by SwiftUI.
    /// - Returns: The styled button body.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
