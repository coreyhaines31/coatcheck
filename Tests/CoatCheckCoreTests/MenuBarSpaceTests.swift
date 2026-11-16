import XCTest
@testable import CoatCheckCore

final class MenuBarSpaceTests: XCTestCase {
    // A 16-inch MacBook Pro: the notch ends at x=956 on a 1728-point screen, leaving 772 points.
    func testShareOfTheRoomRightOfTheNotch() {
        XCTAssertEqual(MenuBarSpace.fraction(widths: [193, 193], clearFrom: 956, screenMaxX: 1728), 0.5, accuracy: 0.0001)
    }

    func testMoreIconsThanRoomGoesPastFull() {
        XCTAssertGreaterThan(MenuBarSpace.fraction(widths: Array(repeating: 40, count: 25), clearFrom: 956, screenMaxX: 1728), 1)
    }

    func testPlaceholdersWithoutWidthTakeNoRoom() {
        XCTAssertEqual(MenuBarSpace.fraction(widths: [0, -5, 386], clearFrom: 956, screenMaxX: 1728), 0.5, accuracy: 0.0001)
    }

    func testNoRoomReadsEmpty() {
        XCTAssertEqual(MenuBarSpace.fraction(widths: [30], clearFrom: 1728, screenMaxX: 1728), 0)
    }
}
