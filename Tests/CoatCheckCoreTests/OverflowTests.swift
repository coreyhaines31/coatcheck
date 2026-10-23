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

    func testDisplayNameDropsRepeatedAppName() {
        let name = Overflow.displayName(app: "WiFi or ISP", label: "WiFi or ISP: Fine: WiFi and ISP both OK")
        XCTAssertEqual(name.name, "WiFi or ISP")
        XCTAssertEqual(name.detail, "Fine: WiFi and ISP both OK")
    }

    func testDisplayNameWithoutLabel() {
        XCTAssertEqual(Overflow.displayName(app: "Granola", label: "").name, "Granola")
        XCTAssertNil(Overflow.displayName(app: "Green Room", label: "Green Room").detail)
    }

    func testSystemIconsUseTheirLabel() {
        let name = Overflow.displayName(app: "Control Center", label: "Wi‑Fi, connected, 3 bars")
        XCTAssertEqual(name.name, "Wi‑Fi")
        XCTAssertEqual(name.detail, "connected, 3 bars")
    }

    func testDisplayNameKeepsStatusText() {
        XCTAssertEqual(Overflow.displayName(app: "Disk Forecast", label: "85 GB").detail, "85 GB")
    }

    func testAlphabeticalIgnoresCaseAndMenuBarPosition() {
        let names = ["Granola", "Stream Deck", "1Password", "cursor", "Green Room"]
        XCTAssertEqual(Overflow.alphabetical(names).map { names[$0] }, ["1Password", "cursor", "Granola", "Green Room", "Stream Deck"])
    }

    func testAlphabeticalKeepsMenuBarOrderForSameName() {
        XCTAssertEqual(Overflow.alphabetical(["Wi‑Fi", "Battery", "Battery"]), [1, 2, 0])
    }
}
