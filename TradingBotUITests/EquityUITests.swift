import XCTest

final class EquityUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", fixture]
        app.launch()
        return app
    }

    func testShowsTheEquityFigureAndOpenPosition() {
        let app = launch(fixture: "full")
        XCTAssertTrue(app.exists(id: "equity.figure", timeout: 10))
        XCTAssertEqual(app.staticTexts["equity.figure"].label, "$116.40")
        XCTAssertTrue(app.exists(id: "equity.openPosition"))
    }

    func testShowsNoOpenPositionForAFlatBot() {
        let app = launch(fixture: "empty")
        XCTAssertTrue(app.exists(id: "equity.figure", timeout: 10))
        XCTAssertFalse(app.element(id: "equity.openPosition").exists)
    }

    func testRefreshControlIsAvailable() {
        let app = launch(fixture: "full")
        XCTAssertTrue(app.buttons["header.refresh"].waitForExistence(timeout: 10))
        app.buttons["header.refresh"].tap()
        // The figure must survive a refresh rather than blanking.
        XCTAssertTrue(app.exists(id: "equity.figure"))
    }
}
