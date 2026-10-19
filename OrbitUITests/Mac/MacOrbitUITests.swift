//
//  MacOrbitUITests.swift
//  OrbitUITests
//

import XCTest

#if os(macOS)
    final class MacOrbitUITests: XCTestCase {
        /// Application under test for the current macOS UI test.
        private let app = XCUIApplication()

        /// Prepares each macOS UI test to stop immediately after a failure.
        override func setUpWithError() throws {
            continueAfterFailure = false
            _ = UITestApp.launch(app)
        }

        /// Cleans up after each macOS UI test.
        override func tearDownWithError() throws {}

        /// Verifies the default macOS timer UI launches with expected controls.
        @MainActor
        func testDefaultTimerStateShowsReadyThirtyMinutesAndPresets() {
            XCTAssertTrue(app.textFields["sessionLabelField"].waitForExistence(timeout: 2))
            XCTAssertTrue(UITestApp.waitForTimerText("30:00", in: app))
            XCTAssertTrue(app.staticTexts["timerStatusText"].exists)
            XCTAssertTrue(app.buttons["startTimerButton"].exists)
            XCTAssertTrue(app.buttons["preset15Button"].exists)
            XCTAssertTrue(app.buttons["preset30Button"].exists)
            XCTAssertTrue(app.buttons["preset45Button"].exists)
            XCTAssertTrue(app.buttons["preset60Button"].exists)
        }

        /// Verifies macOS preset buttons update the visible countdown while idle.
        @MainActor
        func testPresetSelectionUpdatesVisibleCountdown() {
            app.buttons["preset15Button"].click()
            XCTAssertTrue(UITestApp.waitForTimerText("15:00", in: app))

            app.buttons["preset60Button"].click()
            XCTAssertTrue(UITestApp.waitForTimerText("60:00", in: app))
        }

        /// Verifies the macOS start, pause, resume, and stop controls move through the expected UI states.
        @MainActor
        func testStartPauseResumeAndStopFlow() {
            app.buttons["preset15Button"].click()
            app.buttons["startTimerButton"].click()

            XCTAssertTrue(app.buttons["pauseTimerButton"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.buttons["stopTimerButton"].exists)
            XCTAssertFalse(app.textFields["sessionLabelField"].isEnabled)

            app.buttons["pauseTimerButton"].click()
            XCTAssertTrue(app.buttons["startTimerButton"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.buttons["stopTimerButton"].exists)

            app.buttons["startTimerButton"].click()
            XCTAssertTrue(app.buttons["pauseTimerButton"].waitForExistence(timeout: 2))

            app.buttons["stopTimerButton"].click()
            XCTAssertTrue(UITestApp.waitForTimerText("15:00", in: app))
            XCTAssertTrue(app.buttons["startTimerButton"].exists)
            XCTAssertTrue(app.textFields["sessionLabelField"].isEnabled)
        }

        /// Verifies the macOS session label can be edited before the timer starts.
        @MainActor
        func testSessionLabelCanBeEditedWhileIdle() {
            // Session label field shown at the top of the main timer window.
            let field = app.textFields["sessionLabelField"]
            XCTAssertTrue(field.waitForExistence(timeout: 2))

            field.click()
            field.typeKey("a", modifierFlags: [.command])
            field.typeKey(.delete, modifierFlags: [])
            field.typeText("Deep Work")

            XCTAssertEqual(field.value as? String, "Deep Work")
        }

        /// Measures the macOS app launch performance using XCTest's launch metric.
        @MainActor
        func testLaunchPerformance() {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
#endif
