import XCTest
@testable import CoatCheckCore

final class VersionTests: XCTestCase {
    func testVersionIsNeverEmpty() {
        XCTAssertFalse(CoatCheckVersion.current.isEmpty)
    }
}
