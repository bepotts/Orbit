//
//  UITestApp.swift
//  TimeOnTaskUITests
//

import XCTest

/// Shared helpers for launching TimeOnTask in platform UI tests.
enum UITestApp {
    /// Launches a fresh TimeOnTask app instance for a UI test.
    ///
    /// - Parameters:
    ///   - app: The application instance to configure and launch.
    /// - Returns: The launched application under test.
    static func launch(_ app: XCUIApplication = XCUIApplication()) -> XCUIApplication {
        // Application handle that XCTest binds to the configured test target.
        app.launchArguments.append(contentsOf: ["-ApplePersistenceIgnoreState", "YES"])
        app.launch()
        app.activate()
        // Continue through the placeholder login before exercising timer behavior.
        let continueButton = app.buttons["continueWithoutSignInButton"]
        if continueButton.waitForExistence(timeout: 10) {
            continueButton.tap()
        }
        return app
    }

    /// Waits until the visible timer text matches an expected value.
    ///
    /// - Parameters:
    ///   - text: The expected formatted countdown text.
    ///   - app: The application under test.
    /// - Returns: Whether the timer text matched before the timeout.
    static func waitForTimerText(_ text: String, in app: XCUIApplication) -> Bool {
        // Identified timer text used when SwiftUI exposes the element with its test identifier.
        let identifiedTimerText = app.staticTexts["timerRemainingText"]
        // Identified timer button used when the editable countdown is exposed as an accessible button.
        let identifiedTimerButton = app.buttons["timerRemainingText"]
        // Visible timer text used as a fallback when the platform exposes the display by label instead.
        let visibleTimerText = app.staticTexts[text]
        return (identifiedTimerText.exists && identifiedTimerText.label == text)
            || (identifiedTimerButton.exists && identifiedTimerButton.label == text)
            || visibleTimerText.waitForExistence(timeout: 2)
    }
}
