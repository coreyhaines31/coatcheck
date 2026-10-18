import AppKit
import ApplicationServices

/// Rebuilds another app's menu inside Coat Check's, so a hidden icon's menu opens under the hanger.
/// Choosing an item presses the real one through Accessibility.
final class MirroredMenu: NSObject, NSMenuDelegate {
    private let source: AXUIElement
    private var elements: [AXUIElement] = []
    private var submenus: [MirroredMenu] = []

    init(source: AXUIElement) {
        self.source = source
    }

    /// A menu filled in from `source` now, and refreshed each time it opens.
    /// It can't start empty: macOS disables an item whose submenu has nothing in it.
    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        menuNeedsUpdate(menu)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        elements = []
        submenus = []
        for element in MenuBarItems.children(of: source) {
            let title: String = MenuBarItems.attribute(element, kAXTitleAttribute) ?? ""
            let enabled: Bool = MenuBarItems.attribute(element, kAXEnabledAttribute) ?? true
            if title.isEmpty {
                // Untitled, disabled items are separators.
                if !enabled, menu.items.last?.isSeparatorItem == false { menu.addItem(.separator()) }
                continue
            }
            let entry = NSMenuItem(title: title, action: #selector(choose(_:)), keyEquivalent: "")
            entry.target = self
            entry.isEnabled = enabled
            entry.tag = elements.count
            let mark: String? = MenuBarItems.attribute(element, kAXMenuItemMarkCharAttribute)
            if let mark, !mark.isEmpty { entry.state = .on }
            if let source = MenuBarItems.menu(of: element) {
                let mirror = MirroredMenu(source: source)
                submenus.append(mirror)
                entry.submenu = mirror.makeMenu()
                entry.action = nil
            }
            elements.append(element)
            menu.addItem(entry)
        }
        if menu.items.last?.isSeparatorItem == true { menu.removeItem(at: menu.numberOfItems - 1) }
        if menu.items.isEmpty {
            let empty = NSMenuItem(title: "Nothing to show", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }
    }

    /// Presses the real item once Coat Check's menu has closed.
    @objc private func choose(_ sender: NSMenuItem) {
        guard elements.indices.contains(sender.tag) else { return }
        let element = elements[sender.tag]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AXUIElementPerformAction(element, kAXPressAction as CFString)
        }
    }
}
