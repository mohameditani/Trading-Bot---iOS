import XCTest

final class ErrorStateUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testErrorFixtureShowsRetryOnEveryTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", "error"]
        app.launch()

        XCTAssertTrue(app.exists(id: "state.error", timeout: 10))
        XCTAssertTrue(app.buttons["state.retry"].exists)

        app.buttons["tab.trades"].tap()
        XCTAssertTrue(app.exists(id: "state.error"))

        app.buttons["tab.review"].tap()
        XCTAssertTrue(app.exists(id: "state.error"))
    }
}
