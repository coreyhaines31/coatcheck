import AppKit
import CoatCheckCore

/// The hanger icon, which opens a menu of every menu bar icon, including the ones macOS had no room for.
/// An optional divider to its left can also hide icons.
final class MenuBarController: NSObject {
    private let toggle: NSStatusItem
    private var divider: NSStatusItem?
    private let preferences: Preferences
    private var autoHideTimer: Timer?
    /// The icons listed in the open menu, so a choice can be pressed after the menu closes.
    private var listed: [MenuBarItem] = []
    private var mirrors: [MirroredMenu] = []
    private(set) var isHidden = false
    var onOpenSettings: (() -> Void)?
    var onCheckForUpdates: (() -> Void)?

    init(preferences: Preferences) {
        self.preferences = preferences
        // Registered, not written, so a spot the person drags to always wins.
        UserDefaults.standard.register(defaults: StatusItemPlacement.firstLaunchDefaults)
        toggle = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        toggle.autosaveName = StatusItemPlacement.iconName
        super.init()
        if let button = toggle.button {
            button.image = NSImage(systemSymbolName: "hanger", accessibilityDescription: "Coat Check")
            button.target = self
            button.action = #selector(toggleClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("Coat Check")
            button.toolTip = "Coat Check: open any menu bar icon, even ones hidden by the notch"
        }
        setDividerEnabled(preferences.useDivider)
    }

    // MARK: Divider

    func setDividerEnabled(_ enabled: Bool) {
        if enabled, divider == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.autosaveName = StatusItemPlacement.dividerName
            item.button?.image = Self.dividerImage
            item.button?.target = self
            item.button?.action = #selector(dividerClicked)
            item.button?.setAccessibilityLabel("Coat Check divider")
            item.button?.toolTip = "Icons left of this divider can be hidden. Hold ⌘ and drag icons across it."
            divider = item
        } else if !enabled, let item = divider {
            autoHideTimer?.invalidate()
            NSStatusBar.system.removeStatusItem(item)
            divider = nil
            isHidden = false
        }
    }

    /// Hides or returns the icons left of the divider. `byPerson` reveals start the auto-hide countdown.
    /// Returns false when hiding is refused: no divider, or it sits right of the icon.
    @discardableResult
    func setHidden(_ hidden: Bool, byPerson: Bool = true, attempt: Int = 0) -> Bool {
        guard let divider else { return !hidden }
        // Right after launch the items have no place in the menu bar yet, so automatic changes wait for it.
        if !byPerson, !isPlaced, attempt < 20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.setHidden(hidden, byPerson: false, attempt: attempt + 1)
            }
            return true
        }
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        if hidden == isHidden {
            if !hidden && byPerson { scheduleAutoHide() }
            return true
        }
        if hidden {
            guard dividerPlaced else { return false }
            divider.button?.image = nil
            divider.length = Divider.hiddenLength
        } else {
            divider.length = NSStatusItem.variableLength
            divider.button?.image = Self.dividerImage
            if byPerson { scheduleAutoHide() }
        }
        isHidden = hidden
        return true
    }

    /// Whether hiding is safe: the divider exists and sits left of the icon. Always true while hidden.
    var dividerPlaced: Bool {
        guard let divider else { return false }
        return isHidden || Divider.canHide(dividerMinX: divider.button?.window?.frame.minX,
                                           toggleMinX: toggle.button?.window?.frame.minX)
    }

    private var isPlaced: Bool {
        [toggle, divider].compactMap { $0 }.allSatisfy { item in
            guard let frame = item.button?.window?.frame, frame.height > 0 else { return false }
            return NSScreen.screens.contains { $0.frame.intersects(frame) }
        }
    }

    /// The click handlers' version of `setHidden`, which explains a refusal.
    private func personSetHidden(_ hidden: Bool) {
        if !setHidden(hidden) { explainDividerPlacement() }
    }

    @objc private func dividerClicked() { personSetHidden(true) }

    // MARK: Menu

    @objc private func toggleClicked() { showMenu() }

    private func showMenu() {
        let menu = NSMenu()
        mirrors = []
        if MenuBarItems.isTrusted {
            listed = MenuBarItems.all()
            let order = Overflow.alphabetical(listed.map { Overflow.displayName(app: $0.appName, label: $0.label).name })
            let hidden = order.filter { !listed[$0].isVisible }
            let shown = order.filter { listed[$0].isVisible }
            if hidden.isEmpty {
                menu.addItem(.sectionHeader(title: "Every icon fits in the menu bar"))
            } else {
                menu.addItem(.sectionHeader(title: "No room in the menu bar"))
                hidden.forEach { menu.addItem(menuItem(for: $0)) }
            }
            if !shown.isEmpty {
                menu.addItem(.separator())
                menu.addItem(.sectionHeader(title: "In the menu bar"))
                shown.forEach { menu.addItem(menuItem(for: $0)) }
            }
        } else {
            menu.addItem(.sectionHeader(title: "See the icons the notch hides"))
            let allow = menu.addItem(withTitle: "Allow Accessibility Access…", action: #selector(allowAccess), keyEquivalent: "")
            allow.target = self
            allow.toolTip = "Coat Check uses Accessibility to list and open other apps' menu bar icons."
        }
        if divider != nil {
            menu.addItem(.separator())
            menu.addItem(withTitle: isHidden ? "Show Icons Left of Divider" : "Hide Icons Left of Divider",
                         action: #selector(menuToggle), keyEquivalent: "").target = self
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(menuSettings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "Check for Updates…", action: #selector(menuUpdates), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Quit Coat Check", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        toggle.menu = menu
        toggle.button?.performClick(nil)
        toggle.menu = nil
    }

    private func menuItem(for index: Int) -> NSMenuItem {
        let item = listed[index]
        let name = Overflow.displayName(app: item.appName, label: item.label)
        let entry = NSMenuItem(title: name.name, action: #selector(open(_:)), keyEquivalent: "")
        entry.target = self
        entry.tag = index
        if #available(macOS 14.4, *) { entry.subtitle = name.detail }
        if let icon = item.app.icon?.copy() as? NSImage {
            icon.size = NSSize(width: 16, height: 16)
            entry.image = icon
        }
        // Apps that expose their menu get it right here; the rest open in place.
        if let source = MenuBarItems.menu(of: item.element) {
            let mirror = MirroredMenu(source: source)
            mirrors.append(mirror)
            // Setting a submenu also sets the action that opens it, so nothing else may change the action after.
            entry.submenu = mirror.makeMenu()
        }
        return entry
    }

    /// Presses the chosen icon once this menu has closed, so its own menu can open.
    @objc private func open(_ sender: NSMenuItem) {
        guard listed.indices.contains(sender.tag) else { return }
        let item = listed[sender.tag]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { item.press() }
    }

    @objc private func allowAccess() {
        MenuBarItems.requestAccess()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func menuToggle() { personSetHidden(!isHidden) }
    @objc private func menuSettings() { onOpenSettings?() }
    @objc private func menuUpdates() { onCheckForUpdates?() }

    // MARK: Auto-hide

    private func scheduleAutoHide() {
        let delay = preferences.autoHideDelay
        guard delay != .never else { return }
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(delay.rawValue), repeats: false) { [weak self] _ in
            self?.autoHideFired()
        }
    }

    /// Waits while the pointer is in the menu bar, so icons don't vanish mid-click.
    private func autoHideFired() {
        let pointer = NSEvent.mouseLocation
        let inMenuBar = NSScreen.screens.contains { screen in
            screen.frame.contains(pointer) && screen.frame.maxY - pointer.y <= NSStatusBar.system.thickness + 8
        }
        if inMenuBar {
            autoHideTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in self?.autoHideFired() }
        } else {
            setHidden(true, byPerson: false)
        }
    }

    private func explainDividerPlacement() {
        let alert = NSAlert()
        alert.messageText = "Move the divider left of the hanger"
        alert.informativeText = "Coat Check hides the icons to the left of its divider (│). "
            + "Hold ⌘ and drag the divider so it sits just left of the hanger, then try again."
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private static let dividerImage: NSImage = {
        let image = NSImage(size: NSSize(width: 8, height: 16), flipped: false) { bounds in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: NSRect(x: bounds.midX - 1, y: 1, width: 2, height: bounds.height - 2),
                         xRadius: 1, yRadius: 1).fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Coat Check divider"
        return image
    }()
}
