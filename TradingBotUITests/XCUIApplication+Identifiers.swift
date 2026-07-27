import XCTest

extension XCUIApplication {
    /// Looks an element up by identifier regardless of the element *type* SwiftUI chose
    /// for it.
    ///
    /// SwiftUI decides on its own whether a given view surfaces as `otherElement`,
    /// `staticText`, `button`, and that choice can change between OS releases. Tests
    /// that hardcode the type break for reasons that have nothing to do with the app,
    /// so every lookup here goes through `descendants(matching: .any)`.
    func element(id: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func elementCount(id: String) -> Int {
        descendants(matching: .any).matching(identifier: id).count
    }

    func exists(id: String, timeout: TimeInterval = 5) -> Bool {
        element(id: id).waitForExistence(timeout: timeout)
    }
}
