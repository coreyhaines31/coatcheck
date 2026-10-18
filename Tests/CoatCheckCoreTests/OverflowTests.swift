import XCTest
@testable import CoatCheckCore

final class OverflowTests: XCTestCase {
    // Corey's MacBook: the notch ends at x=956 on a 1728-point screen.
    func testVisibleRightOfTheNotch() {
        XCTAssertTrue(Overflow.isVisible(CGRect(x: 1106, y: 0, width: 31, height: 24), clearFrom: 956, screenMaxX: 1728))
    }

    func testHiddenBesideTheNotch() {
        XCTAssertFalse(Overflow.isVisible(CGRect(x: 924, y: 0, width: 80, height: 24), clearFrom: 956, screenMaxX: 1728))
    }

    func testHiddenOffTheLeftEdge() {
        XCTAssertFalse(Overflow.isVisible(CGRect(x: -1, y: 0, width: 43, height: 24), clearFrom: 956, screenMaxX: 1728))
    }

    func testPlaceholdersWithoutWidthAreNotIcons() {
        XCTAssertFalse(Overflow.isVisible(CGRect(x: 1200, y: 0, width: 0, height: 0), clearFrom: 956, screenMaxX: 1728))
    }

    private let items: [(app: String, label: String)] = [
        ("Spare", "Spare"), ("Green Room", "Camera"), ("Green Room", "Microphone"), ("Spotify", "")
    ]

    func testMatchesAppName() {
        XCTAssertEqual(Overflow.match("spare", in: items), 0)
    }

    func testMatchesPrefix() {
        XCTAssertEqual(Overflow.match("spot", in: items), 3)
    }

    func testMatchesAppAndLabel() {
        XCTAssertEqual(Overflow.match("Green Room: Microphone", in: items), 2)
    }

    func testSeveralIconsFromOneAppPickTheFirst() {
        XCTAssertEqual(Overflow.match("green room", in: items), 1)
    }

    func testAmbiguousAcrossAppsFails() {
        XCTAssertNil(Overflow.match("sp", in: items))
    }

    func testUnknownFails() {
        XCTAssertNil(Overflow.match("bartender", in: items))
    }
}
