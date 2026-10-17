import XCTest
@testable import CoatCheckCore

final class ScreenRuleTests: XCTestCase {
    func testLaptopScreenAlone() {
        XCTAssertEqual(ScreenRule.laptopScreenOnly(builtIn: [true]), true)
    }

    func testLaptopWithExternalDisplay() {
        XCTAssertEqual(ScreenRule.laptopScreenOnly(builtIn: [true, false]), false)
    }

    func testClamshellCountsAsExternal() {
        XCTAssertEqual(ScreenRule.laptopScreenOnly(builtIn: [false]), false)
    }

    func testNoScreensIsUnknown() {
        XCTAssertNil(ScreenRule.laptopScreenOnly(builtIn: []))
    }

    func testHidesWhenExternalDisplayDisconnects() {
        XCTAssertEqual(ScreenRule.hidden(laptopScreenOnly: true, previously: false), true)
    }

    func testShowsWhenExternalDisplayConnects() {
        XCTAssertEqual(ScreenRule.hidden(laptopScreenOnly: false, previously: true), false)
    }

    func testAppliesAtLaunch() {
        XCTAssertEqual(ScreenRule.hidden(laptopScreenOnly: true, previously: nil), true)
    }

    func testLeavesThePersonsChoiceWhenNothingChanged() {
        XCTAssertNil(ScreenRule.hidden(laptopScreenOnly: true, previously: true))
        XCTAssertNil(ScreenRule.hidden(laptopScreenOnly: nil, previously: false))
    }
}
