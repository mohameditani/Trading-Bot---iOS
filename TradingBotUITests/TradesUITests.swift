import XCTest

final class TradesUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchOnTrades(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", fixture]
        app.launch()
        XCTAssertTrue(app.buttons["tab.trades"].waitForExistence(timeout: 10))
        app.buttons["tab.trades"].tap()
        return app
    }

    /// Counts *trade rows* for a symbol. Scoped to `trade.row` on purpose: the
    /// breakdown tables list every symbol regardless of the active filter, so an
    /// unscoped label search would never reach zero.
    private func rowCount(_ app: XCUIApplication, containing text: String) -> Int {
        app.descendants(matching: .any)
            .matching(identifier: "trade.row")
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .count
    }

    func testFilteringBySymbolChangesTheVisibleRows() {
        let app = launchOnTrades(fixture: "full")
        XCTAssertTrue(app.buttons["filter.all"].waitForExistence(timeout: 5))

        XCTAssertGreaterThan(rowCount(app, containing: "SOLUSDT"), 0)
        XCTAssertGreaterThan(rowCount(app, containing: "BTCUSDT"), 0)

        app.buttons["filter.btc"].tap()
        XCTAssertGreaterThan(rowCount(app, containing: "BTCUSDT"), 0)
        XCTAssertEqual(
            rowCount(app, containing: "SOLUSDT"), 0,
            "BTC filter must hide SOL trades"
        )

        app.buttons["filter.all"].tap()
        XCTAssertGreaterThan(rowCount(app, containing: "SOLUSDT"), 0)
    }

    func testBreakdownSectionsArePresent() {
        let app = launchOnTrades(fixture: "full")
        XCTAssertTrue(app.exists(id: "breakdown.bysymbol"))
        XCTAssertTrue(app.exists(id: "breakdown.byregime"))
    }

    func testEmptyHistoryHidesTheBreakdowns() {
        let app = launchOnTrades(fixture: "empty")
        XCTAssertTrue(app.exists(id: "state.empty"))
        XCTAssertFalse(app.element(id: "breakdown.bysymbol").exists)
    }
}
