import XCTest

final class LaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testLaunchesOnTheEquityTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", "full"]
        app.launch()
        XCTAssertTrue(app.buttons["tab.equity"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tab.trades"].exists)
        XCTAssertTrue(app.buttons["tab.review"].exists)
    }

    func testSwitchesBetweenAllThreeTabs() {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", "full"]
        app.launch()
        XCTAssertTrue(app.buttons["tab.trades"].waitForExistence(timeout: 10))

        app.buttons["tab.trades"].tap()
        XCTAssertTrue(app.staticTexts["screen.trades"].waitForExistence(timeout: 5))

        app.buttons["tab.review"].tap()
        XCTAssertTrue(app.staticTexts["screen.review"].waitForExistence(timeout: 5))

        app.buttons["tab.equity"].tap()
        XCTAssertTrue(app.staticTexts["screen.equity"].waitForExistence(timeout: 5))
    }
}
