import AppKit
import ApplicationServices
import CoatCheckCore

/// Another app's menu bar icon, read through Accessibility.
struct MenuBarItem {
    let app: NSRunningApplication
    let element: AXUIElement
    /// In Accessibility coordinates: origin at the top left of the main screen.
    let frame: CGRect
    let label: String

    var appName: String { app.localizedName ?? app.bundleIdentifier ?? "Unknown app" }

    /// False when macOS had no room to show it.
    let isVisible: Bool

    var summary: Command.Item {
        Command.Item(app: appName, bundleIdentifier: app.bundleIdentifier, label: label, visible: isVisible,
                     x: frame.minX, width: frame.width)
    }

    /// Opens the icon's menu or panel, as a click would.
    @discardableResult
    func press() -> Bool {
        // Apps showing a menu are busy until it closes, so the press times out even though it worked.
        [.success, .cannotComplete].contains(AXUIElementPerformAction(element, kAXPressAction as CFString))
    }
}

enum MenuBarItems {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that sends people to Privacy & Security → Accessibility.
    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Every app's menu bar icons. Apps that don't answer within a quarter second are skipped.
    static func all() -> [MenuBarItem] {
        let me = ProcessInfo.processInfo.processIdentifier
        let clear = clearArea()
        return NSWorkspace.shared.runningApplications
            .filter { ($0.processIdentifier != me && $0.activationPolicy != .prohibited) || isSystemOwner($0) }
            .flatMap { items(of: $0, clear: clear) }
            .sorted { $0.frame.minX < $1.frame.minX }
    }

    /// macOS's own icons (Wi-Fi, battery, clock) live in background processes.
    private static func isSystemOwner(_ app: NSRunningApplication) -> Bool {
        ["com.apple.controlcenter", "com.apple.systemuiserver", "com.apple.Spotlight", "com.apple.TextInputMenuAgent"]
            .contains(app.bundleIdentifier ?? "")
    }

    /// Where icons can start showing on the main screen: right of the notch, or right of the frontmost app's menus.
    static func clearArea() -> (from: CGFloat, maxX: CGFloat) {
        guard let screen = NSScreen.screens.first else { return (0, 0) }
        var from = screen.auxiliaryTopRightArea?.minX ?? 0
        if let app = NSWorkspace.shared.frontmostApplication {
            let element = AXUIElementCreateApplication(app.processIdentifier)
            AXUIElementSetMessagingTimeout(element, 0.25)
            if let bar: AXUIElement = attribute(element, kAXMenuBarAttribute),
               let menus: [AXUIElement] = attribute(bar, kAXChildrenAttribute) {
                from = max(from, menus.compactMap(frame(of:)).map(\.maxX).max() ?? 0)
            }
        }
        return (from, screen.frame.maxX)
    }

    private static func items(of app: NSRunningApplication, clear: (from: CGFloat, maxX: CGFloat)) -> [MenuBarItem] {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(element, 0.25)
        guard let bar: AXUIElement = attribute(element, kAXExtrasMenuBarAttribute),
              let children: [AXUIElement] = attribute(bar, kAXChildrenAttribute) else { return [] }
        return children.compactMap { child in
            guard let frame = frame(of: child), frame.width > 0 else { return nil }
            let label = [kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute]
                .lazy.compactMap { (key: String) -> String? in attribute(child, key) }
                .first { !$0.isEmpty } ?? ""
            return MenuBarItem(app: app, element: child, frame: frame, label: label,
                               isVisible: Overflow.isVisible(frame, clearFrom: clear.from, screenMaxX: clear.maxX))
        }
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        guard let position: AXValue = attribute(element, kAXPositionAttribute),
              let size: AXValue = attribute(element, kAXSizeAttribute) else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        AXValueGetValue(position, .cgPoint, &origin)
        AXValueGetValue(size, .cgSize, &extent)
        return CGRect(origin: origin, size: extent)
    }

    static func children(of element: AXUIElement) -> [AXUIElement] {
        attribute(element, kAXChildrenAttribute) ?? []
    }

    /// An element's menu, when its app exposes one. macOS's own icons don't.
    static func menu(of element: AXUIElement) -> AXUIElement? {
        children(of: element).first { (attribute($0, kAXRoleAttribute) as String?) == kAXMenuRole }
    }

    static func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }
}
