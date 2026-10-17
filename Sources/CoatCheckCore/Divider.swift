import CoreGraphics

/// The divider status item hides the icons to its left by growing wide enough to push them off the menu bar.
public enum Divider {
    /// Wider than any menu bar, so everything to the divider's left ends up off-screen.
    public static let hiddenLength: CGFloat = 10_000

    /// Hiding is only safe while the divider sits to the left of the Coat Check icon.
    /// Otherwise the divider would push the icon itself off-screen, with no way to click it back.
    public static func canHide(dividerMinX: CGFloat?, toggleMinX: CGFloat?) -> Bool {
        guard let dividerMinX, let toggleMinX else { return false }
        return dividerMinX < toggleMinX
    }
}

/// How long revealed icons stay out before Coat Check checks them again.
public enum AutoHideDelay: Int, CaseIterable, Identifiable {
    case never = 0
    case fiveSeconds = 5
    case tenSeconds = 10
    case thirtySeconds = 30
    case oneMinute = 60

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .never: "Never"
        case .oneMinute: "After 1 minute"
        default: "After \(rawValue) seconds"
        }
    }
}

/// Where the Coat Check icon and divider start out.
public enum StatusItemPlacement {
    public static let iconName = "CoatCheckIcon"
    public static let dividerName = "CoatCheckDivider"

    /// macOS keeps each status item's spot under this key, counted from the right end of the menu bar.
    public static func positionKey(_ name: String) -> String { "NSStatusItem Preferred Position \(name)" }

    /// New status items go to the left end, which is off-screen beside the notch when the menu bar is crowded.
    /// Starting at the right end keeps both visible, with the divider just left of the icon.
    public static var firstLaunchDefaults: [String: Double] {
        [positionKey(iconName): 1, positionKey(dividerName): 2]
    }
}
