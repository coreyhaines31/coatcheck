import AppKit
import CoatCheckCore

/// The Coat Check icon and the divider to its left. Icons dragged left of the divider are the checked ones.
final class MenuBarController: NSObject {
    private let toggle: NSStatusItem
    private let divider: NSStatusItem
    private let preferences: Preferences
    private var autoHideTimer: Timer?
    private(set) var isHidden = false
    var onChange: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onCheckForUpdates: (() -> Void)?

    init(preferences: Preferences) {
        self.preferences = preferences
        // Registered, not written, so a spot the person drags to always wins.
        UserDefaults.standard.register(defaults: StatusItemPlacement.firstLaunchDefaults)
        toggle = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        toggle.autosaveName = StatusItemPlacement.iconName
        divider = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        divider.autosaveName = StatusItemPlacement.dividerName
        super.init()
        if let button = toggle.button {
            button.image = NSImage(systemSymbolName: "hanger", accessibilityDescription: "Coat Check")
            button.target = self
            button.action = #selector(toggleClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        if let button = divider.button {
            button.image = Self.dividerImage
            button.target = self
            button.action = #selector(dividerClicked)
            button.setAccessibilityLabel("Coat Check divider")
            button.toolTip = "Icons left of this divider are checked. Hold ⌘ and drag icons to move them."
        }
        updateToggle()
    }

    /// Checks or returns the icons left of the divider. `byPerson` reveals start the auto-hide countdown.
    func setHidden(_ hidden: Bool, byPerson: Bool = true) {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        if hidden == isHidden {
            if !hidden && byPerson { scheduleAutoHide() }
            return
        }
        if hidden {
            guard Divider.canHide(dividerMinX: divider.button?.window?.frame.minX,
                                  toggleMinX: toggle.button?.window?.frame.minX) else {
                if byPerson { explainDividerPlacement() }
                return
            }
            divider.button?.image = nil
            divider.length = Divider.hiddenLength
        } else {
            divider.length = NSStatusItem.variableLength
            divider.button?.image = Self.dividerImage
            if byPerson { scheduleAutoHide() }
        }
        isHidden = hidden
        updateToggle()
        onChange?()
    }

    @objc private func toggleClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            setHidden(!isHidden)
        }
    }

    @objc private func dividerClicked() { setHidden(true) }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: isHidden ? "Show Icons" : "Hide Icons", action: #selector(menuToggle), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(menuSettings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "Check for Updates…", action: #selector(menuUpdates), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Coat Check", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        toggle.menu = menu
        toggle.button?.performClick(nil)
        toggle.menu = nil
    }

    @objc private func menuToggle() { setHidden(!isHidden) }
    @objc private func menuSettings() { onOpenSettings?() }
    @objc private func menuUpdates() { onCheckForUpdates?() }

    private func updateToggle() {
        let state = isHidden ? "icons checked" : "icons out"
        toggle.button?.setAccessibilityLabel("Coat Check, \(state)")
        toggle.button?.toolTip = isHidden ? "Click to show checked icons" : "Click to check icons left of the divider"
    }

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
