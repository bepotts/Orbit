//
//  Enums.swift
//  Orbit
//

import Foundation

/// Keyboard focus targets for timer controls.
enum FocusedControl: Hashable {
    /// Primary timer button focus target.
    case primaryButton

    /// Stop button focus target.
    case stopButton

    /// Preset duration button focus target.
    case presetButton(TimeInterval)

    /// Quit button focus target.
    case quitButton
}
