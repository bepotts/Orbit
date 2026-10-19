//
//  IOSOrbitLaunchUITests.swift
//  OrbitUITests
//

import XCTest

#if os(iOS)
    final class IOSOrbitLaunchUITests: XCTestCase {
        /// Tells XCTest to run this iOS and iPadOS launch screenshot test across configured UI appearances.
        override static var runsForEachTargetApplicationUIConfiguration: Bool {
            true
        }

        /// Prepares the iOS and iPadOS launch test to stop immediately after a failure.
        override func setUpWithError() throws {
            continueAfterFailure = false
        }

        /// Cleans up after each iOS or iPadOS launch test.
        override func tearDownWithError() throws {}

        /// Launches the iOS or iPadOS app and stores a screenshot attachment for review.
        @MainActor
        func testLaunch() {
            // Application handle used to launch and screenshot the app under test.
            let app = UITestApp.launch()
            // Screenshot attachment kept with the test result for launch screen review.
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "iOS Launch Screen"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
#endif
