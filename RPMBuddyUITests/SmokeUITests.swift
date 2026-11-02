import XCTest

@MainActor
class RPMBuddyUITestCase: XCTestCase {
    let timeout: TimeInterval = 12

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }

    func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui_test_reset",
            "-ui_test_skip_mic_onboarding",
            "-ui_test_mock_bpm", "120"
        ] + extraArguments
        app.launch()
        return app
    }
}

@MainActor
final class SmokeUITests: RPMBuddyUITestCase {
    func testDetectorShowsMockBPM() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["RPM Buddy"].waitForExistence(timeout: timeout))

        let listen = app.buttons["detector.listen.toggle"]
        XCTAssertTrue(listen.waitForExistence(timeout: timeout))
        listen.tap()

        let bpm = app.staticTexts["detector.bpm.value"]
        XCTAssertTrue(bpm.waitForExistence(timeout: timeout))
        XCTAssertTrue(bpm.label.contains("120"))

        let timestamp = app.staticTexts["detector.logged.timestamp"]
        XCTAssertTrue(timestamp.waitForExistence(timeout: timeout))
        XCTAssertFalse(timestamp.label.isEmpty)

        let alternatives = app.otherElements["detector.tempo.alternatives"]
        XCTAssertTrue(alternatives.waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["detector.tempo.alternative.60"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["detector.tempo.alternative.120"].waitForExistence(timeout: timeout))

        let confidence = app.otherElements["detector.confidence.meter"]
        XCTAssertTrue(confidence.waitForExistence(timeout: timeout))

        let tooFast = app.buttons["detector.count.tooFast"]
        XCTAssertTrue(tooFast.waitForExistence(timeout: timeout))
        if !tooFast.isHittable {
            app.swipeUp()
        }
        tooFast.tap()
        XCTAssertTrue(bpm.label.contains("60"))
    }

    func testSettingsOpensFromDetector() {
        let app = launchApp()
        let settings = app.buttons["detector.settings.button"]
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: timeout))
    }
}
