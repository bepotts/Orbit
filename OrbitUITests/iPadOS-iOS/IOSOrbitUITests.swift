//
//  IOSOrbitUITests.swift
//  OrbitUITests
//

import XCTest

#if os(iOS)
    final class IOSOrbitUITests: XCTestCase {
        /// Application under test for the current iOS or iPadOS UI test.
        private let app = XCUIApplication()

        /// Prepares each iOS or iPadOS UI test to stop immediately after a failure.
        override func setUpWithError() throws {
            continueAfterFailure = false
            _ = UITestApp.launch(app)
        }

        /// Cleans up after each iOS or iPadOS UI test.
        override func tearDownWithError() throws {}

        /// Verifies the default iOS and iPadOS timer UI launches with expected controls.
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

        /// Verifies iOS and iPadOS preset buttons update the visible countdown while idle.
        @MainActor
        func testPresetSelectionUpdatesVisibleCountdown() {
            app.buttons["preset15Button"].tap()
            XCTAssertTrue(UITestApp.waitForTimerText("15:00", in: app))

            app.buttons["preset60Button"].tap()
            XCTAssertTrue(UITestApp.waitForTimerText("60:00", in: app))
        }

        /// Verifies the iOS and iPadOS start, pause, resume, and stop controls move through expected UI states.
        @MainActor
        func testStartPauseResumeAndStopFlow() {
            app.buttons["preset15Button"].tap()
            app.buttons["startTimerButton"].tap()

            XCTAssertTrue(app.buttons["pauseTimerButton"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.buttons["stopTimerButton"].exists)
            XCTAssertFalse(app.textFields["sessionLabelField"].isEnabled)

            app.buttons["pauseTimerButton"].tap()
            XCTAssertTrue(app.buttons["startTimerButton"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.buttons["stopTimerButton"].exists)

            app.buttons["startTimerButton"].tap()
            XCTAssertTrue(app.buttons["pauseTimerButton"].waitForExistence(timeout: 2))

            app.buttons["stopTimerButton"].tap()
            XCTAssertTrue(UITestApp.waitForTimerText("15:00", in: app))
            XCTAssertTrue(app.buttons["startTimerButton"].exists)
            XCTAssertTrue(app.textFields["sessionLabelField"].isEnabled)
        }

        /// Verifies the iOS and iPadOS session label can be edited before the timer starts.
        @MainActor
        func testSessionLabelCanBeEditedWhileIdle() {
            // Session label field shown at the top of the main timer view.
            let field = app.textFields["sessionLabelField"]
            XCTAssertTrue(field.waitForExistence(timeout: 2))

            field.tap()
            field.press(forDuration: 1.1)
            app.menuItems["Select All"].tap()
            field.typeText("Deep Work")

            XCTAssertEqual(field.value as? String, "Deep Work")
        }

        /// Measures the iOS and iPadOS app launch performance using XCTest's launch metric.
        @MainActor
        func testLaunchPerformance() {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
#endif
