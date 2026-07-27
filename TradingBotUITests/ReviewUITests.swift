import XCTest

final class ReviewUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchOnReview(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", fixture]
        app.launch()
        XCTAssertTrue(app.buttons["tab.review"].waitForExistence(timeout: 10))
        app.buttons["tab.review"].tap()
        return app
    }

    func testShowsReportVetoAndLessonsWhenTheLayerIsOn() {
        let app = launchOnReview(fixture: "full")
        XCTAssertTrue(app.exists(id: "review.report"))
        XCTAssertTrue(app.exists(id: "review.vetoLog"))
        XCTAssertTrue(app.exists(id: "review.lessons"))
        XCTAssertEqual(app.staticTexts["review.date"].label, "2026-06-30")
        XCTAssertEqual(app.elementCount(id: "review.placeholder"), 0)
    }

    // The design's fourth screen.
    func testShowsExactlyThreePlaceholdersWhenTheLayerIsOff() {
        let app = launchOnReview(fixture: "aiNull")
        XCTAssertTrue(app.exists(id: "review.placeholder"))
        XCTAssertEqual(app.elementCount(id: "review.placeholder"), 3)
        XCTAssertFalse(app.element(id: "review.report").exists)
        XCTAssertFalse(app.element(id: "review.vetoLog").exists)
        XCTAssertEqual(app.staticTexts["review.date"].label, "off")
    }
}
