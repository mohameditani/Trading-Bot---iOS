import XCTest

final class LaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(
            app.otherElements["root.placeholder"].waitForExistence(timeout: 10)
                || app.staticTexts["root.placeholder"].waitForExistence(timeout: 10)
        )
    }
}
