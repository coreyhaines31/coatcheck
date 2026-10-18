import Foundation

/// Messages between the `coatcheck` command and the running app, sent as distributed notifications
/// with string-only user info.
public enum Command {
    public static let request = Notification.Name("com.coatcheckformac.CoatCheck.command.request")
    public static let reply = Notification.Name("com.coatcheckformac.CoatCheck.command.reply")
    public static let bundleIdentifier = "com.coatcheckformac.CoatCheck"

    public enum Action: String, CaseIterable {
        case show, hide, toggle, status, list, click
    }

    public struct Request: Equatable {
        public var id: String
        public var action: Action
        /// The icon to click: an app name, optionally followed by the icon's label.
        public var target: String

        public init(id: String = UUID().uuidString, action: Action, target: String = "") {
            self.id = id
            self.action = action
            self.target = target
        }

        public init?(userInfo: [AnyHashable: Any]?) {
            guard let info = userInfo as? [String: String], let id = info["id"],
                  let action = info["action"].flatMap(Action.init(rawValue:)) else { return nil }
            self.init(id: id, action: action, target: info["target"] ?? "")
        }

        public var userInfo: [String: String] { ["id": id, "action": action.rawValue, "target": target] }
    }

    /// One menu bar icon, as `coatcheck list` shows it.
    public struct Item: Equatable, Codable {
        public var app: String
        public var bundleIdentifier: String?
        public var label: String
        /// False when macOS had no room to show it.
        public var visible: Bool
        public var x: Double
        public var width: Double

        public init(app: String, bundleIdentifier: String?, label: String, visible: Bool, x: Double, width: Double) {
            self.app = app
            self.bundleIdentifier = bundleIdentifier
            self.label = label
            self.visible = visible
            self.x = x
            self.width = width
        }
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
        /// Whether Coat Check may read other apps' menu bar icons.
        public var accessibility: Bool
        public var items: [Item]?
        /// What happened, for `click`.
        public var message: String?

        public init(id: String, hidden: Bool, dividerPlaced: Bool, laptopScreenOnly: Bool?,
                    hideOnLaptopScreen: Bool, version: String, accessibility: Bool = false,
                    items: [Item]? = nil, message: String? = nil) {
            self.id = id
            self.hidden = hidden
            self.dividerPlaced = dividerPlaced
            self.laptopScreenOnly = laptopScreenOnly
            self.hideOnLaptopScreen = hideOnLaptopScreen
            self.version = version
            self.accessibility = accessibility
            self.items = items
            self.message = message
        }

        public init?(userInfo: [AnyHashable: Any]?) {
            guard let info = userInfo as? [String: String], let id = info["id"] else { return nil }
            self.init(id: id, hidden: info["hidden"] == "true", dividerPlaced: info["dividerPlaced"] != "false",
                      laptopScreenOnly: info["laptopScreenOnly"].flatMap { Bool($0) },
                      hideOnLaptopScreen: info["hideOnLaptopScreen"] == "true", version: info["version"] ?? "",
                      accessibility: info["accessibility"] == "true",
                      items: info["items"].flatMap { try? JSONDecoder().decode([Item].self, from: Data($0.utf8)) },
                      message: info["message"])
        }

        public var userInfo: [String: String] {
            var info = ["id": id, "hidden": String(hidden), "dividerPlaced": String(dividerPlaced),
                        "hideOnLaptopScreen": String(hideOnLaptopScreen), "version": version]
            info["laptopScreenOnly"] = laptopScreenOnly.map { String($0) }
            info["accessibility"] = String(accessibility)
            info["items"] = items.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) }
            info["message"] = message
            return info
        }

        enum CodingKeys: String, CodingKey {
            case hidden, dividerPlaced, laptopScreenOnly, hideOnLaptopScreen, version, accessibility, items, message
        }
    }
}
