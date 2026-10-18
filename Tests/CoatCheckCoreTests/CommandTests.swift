import XCTest
@testable import CoatCheckCore

final class CommandTests: XCTestCase {
    func testRequestRoundTrips() {
        let request = Command.Request(action: .toggle)
        XCTAssertEqual(Command.Request(userInfo: request.userInfo), request)
    }

    func testUnknownActionIsRejected() {
        XCTAssertNil(Command.Request(userInfo: ["id": "1", "action": "explode"]))
    }

    func testReplyRoundTrips() {
        let reply = Command.Reply(id: "1", hidden: true, divider: true, dividerPlaced: false, laptopScreenOnly: true,
                                  hideOnLaptopScreen: true, version: "0.1.0")
        XCTAssertEqual(Command.Reply(userInfo: reply.userInfo), reply)
    }

    func testReplyKeepsUnknownScreens() {
        let reply = Command.Reply(id: "1", hidden: false, dividerPlaced: true, laptopScreenOnly: nil,
                                  hideOnLaptopScreen: false, version: "0.1.0")
        XCTAssertNil(Command.Reply(userInfo: reply.userInfo)?.laptopScreenOnly)
    }

    func testReplyCarriesItems() {
        let item = Command.Item(app: "Spare", bundleIdentifier: "com.spareformac.Spare", label: "Spare",
                                visible: false, x: 640, width: 32)
        let reply = Command.Reply(id: "1", hidden: false, dividerPlaced: true, laptopScreenOnly: true,
                                  hideOnLaptopScreen: false, version: "0.1.0", accessibility: true, items: [item])
        XCTAssertEqual(Command.Reply(userInfo: reply.userInfo), reply)
    }

    func testClickRequestKeepsTarget() {
        let request = Command.Request(action: .click, target: "Spare")
        XCTAssertEqual(Command.Request(userInfo: request.userInfo)?.target, "Spare")
    }
}
