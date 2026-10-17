import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let updater = Updater()
    private var menuBar: MenuBarController?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let menuBar = MenuBarController(preferences: preferences)
        menuBar.onOpenSettings = { [weak self] in self?.showSettings() }
        menuBar.onCheckForUpdates = { [weak self] in self?.checkForUpdates() }
        self.menuBar = menuBar
        preferences.applyLaunchAtLoginDefault()
        if preferences.isFirstLaunch {
            preferences.markLaunched()
            showSettings()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    private func checkForUpdates() { updater.checkForUpdates() }

    private func showSettings() {
        if settingsWindow == nil {
            let view = SettingsView(preferences: preferences) { [weak self] in self?.checkForUpdates() }
            let created = NSWindow(contentViewController: NSHostingController(rootView: view))
            created.title = "Coat Check"
            created.styleMask = [.titled, .closable]
            created.isReleasedWhenClosed = false
            created.center()
            settingsWindow = created
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
