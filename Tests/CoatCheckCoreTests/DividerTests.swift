import XCTest
@testable import CoatCheckCore

final class DividerTests: XCTestCase {
    func testHidesWhenDividerIsLeftOfTheIcon() {
        XCTAssertTrue(Divider.canHide(dividerMinX: 1200, toggleMinX: 1240))
    }

    func testRefusesWhenDividerIsRightOfTheIcon() {
        XCTAssertFalse(Divider.canHide(dividerMinX: 1300, toggleMinX: 1240))
    }

    func testRefusesWhenEitherPositionIsUnknown() {
        XCTAssertFalse(Divider.canHide(dividerMinX: nil, toggleMinX: 1240))
        XCTAssertFalse(Divider.canHide(dividerMinX: 1200, toggleMinX: nil))
    }

    func testDelayTitles() {
        XCTAssertEqual(AutoHideDelay.never.title, "Never")
        XCTAssertEqual(AutoHideDelay.tenSeconds.title, "After 10 seconds")
        XCTAssertEqual(AutoHideDelay.oneMinute.title, "After 1 minute")
    }
}

final class StatusItemPlacementTests: XCTestCase {
    func testDividerStartsLeftOfTheIcon() {
        let defaults = StatusItemPlacement.firstLaunchDefaults
        let icon = defaults[StatusItemPlacement.positionKey(StatusItemPlacement.iconName)]
        let divider = defaults[StatusItemPlacement.positionKey(StatusItemPlacement.dividerName)]
        XCTAssertNotNil(icon)
        XCTAssertGreaterThan(divider ?? 0, icon ?? 0)
    }
}
