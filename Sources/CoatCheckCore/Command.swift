import Foundation

/// Messages between the `coatcheck` command and the running app, sent as distributed notifications
/// with string-only user info.
public enum Command {
    public static let request = Notification.Name("com.coatcheckformac.CoatCheck.command.request")
    public static let reply = Notification.Name("com.coatcheckformac.CoatCheck.command.reply")
    public static let bundleIdentifier = "com.coatcheckformac.CoatCheck"

    public enum Action: String, CaseIterable {
        case show, hide, toggle, status
    }

    public struct Request: Equatable {
        public var id: String
        public var action: Action

        public init(id: String = UUID().uuidString, action: Action) {
            self.id = id
            self.action = action
        }

        public init?(userInfo: [AnyHashable: Any]?) {
            guard let info = userInfo as? [String: String], let id = info["id"],
                  let action = info["action"].flatMap(Action.init(rawValue:)) else { return nil }
            self.init(id: id, action: action)
        }

        public var userInfo: [String: String] { ["id": id, "action": action.rawValue] }
    }

    /// The app's state after handling a request.
    public struct Reply: Equatable, Encodable {
        public var id: String
        public var hidden: Bool
        /// False when the divider sits right of the Coat Check icon, so hiding was refused.
        public var dividerPlaced: Bool
        public var laptopScreenOnly: Bool?
        public var hideOnLaptopScreen: Bool
        public var version: String

        public init(id: String, hidden: Bool, dividerPlaced: Bool, laptopScreenOnly: Bool?,
                    hideOnLaptopScreen: Bool, version: String) {
            self.id = id
            self.hidden = hidden
            self.dividerPlaced = dividerPlaced
            self.laptopScreenOnly = laptopScreenOnly
            self.hideOnLaptopScreen = hideOnLaptopScreen
            self.version = version
        }

        public init?(userInfo: [AnyHashable: Any]?) {
            guard let info = userInfo as? [String: String], let id = info["id"] else { return nil }
            self.init(id: id, hidden: info["hidden"] == "true", dividerPlaced: info["dividerPlaced"] != "false",
                      laptopScreenOnly: info["laptopScreenOnly"].flatMap { Bool($0) },
                      hideOnLaptopScreen: info["hideOnLaptopScreen"] == "true", version: info["version"] ?? "")
        }

        public var userInfo: [String: String] {
            var info = ["id": id, "hidden": String(hidden), "dividerPlaced": String(dividerPlaced),
                        "hideOnLaptopScreen": String(hideOnLaptopScreen), "version": version]
            info["laptopScreenOnly"] = laptopScreenOnly.map { String($0) }
            return info
        }

        enum CodingKeys: String, CodingKey {
            case hidden, dividerPlaced, laptopScreenOnly, hideOnLaptopScreen, version
        }
    }
}
