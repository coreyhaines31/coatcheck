import AppKit
import Combine
import SwiftUI
import CoatCheckCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let updater = Updater()
    private var menuBar: MenuBarController?
    private var settingsWindow: NSWindow?
    private let screens = ScreenWatcher()
    private var hideOnLaptopObserver: AnyCancellable?
    private var welcomeObserver: NSObjectProtocol?
    private var commands: CommandListener?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let menuBar = MenuBarController(preferences: preferences)
        menuBar.onOpenSettings = { [weak self] in self?.showSettings() }
        menuBar.onCheckForUpdates = { [weak self] in self?.checkForUpdates() }
        self.menuBar = menuBar
        preferences.applyLaunchAtLoginDefault()
        screens.onChange = { [weak self] now, previously in self?.applyScreenRule(now: now, previously: previously) }
        screens.start()
        commands = CommandListener { [unowned self] in handle($0) }
        // @Published sends before the new value is stored, so read it on the next pass.
        hideOnLaptopObserver = preferences.$hideOnLaptopScreen.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] enabled in
            guard let self, enabled else { return }
            applyScreenRule(now: screens.laptopScreenOnly, previously: nil)
        }
        if preferences.isFirstLaunch {
            preferences.markLaunched()
            showSettings()
            // Nothing disappears until the person has read how checking works.
            welcomeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                                                     object: settingsWindow, queue: .main) { [weak self] _ in
                guard let self else { return }
                if let welcomeObserver { NotificationCenter.default.removeObserver(welcomeObserver) }
                welcomeObserver = nil
                applyScreenRule(now: screens.laptopScreenOnly, previously: nil)
            }
        } else {
            applyScreenRule(now: screens.laptopScreenOnly, previously: nil)
        }
    }

    private func handle(_ request: Command.Request) -> Command.Reply {
        var items: [Command.Item]?
        var message: String?
        if let menuBar {
            switch request.action {
            case .show: menuBar.setHidden(false)
            case .hide: menuBar.setHidden(true)
            case .toggle: menuBar.setHidden(!menuBar.isHidden)
            case .status: break
            case .list:
                if !MenuBarItems.isTrusted { MenuBarItems.requestAccess() }
                items = MenuBarItems.all().map(\.summary)
            case .click: message = click(request.target)
            }
        }
        return Command.Reply(id: request.id, hidden: menuBar?.isHidden ?? false, dividerPlaced: menuBar?.dividerPlaced ?? false,
                             laptopScreenOnly: screens.laptopScreenOnly, hideOnLaptopScreen: preferences.hideOnLaptopScreen,
                             version: CoatCheckVersion.current, accessibility: MenuBarItems.isTrusted,
                             items: items, message: message)
    }

    private func click(_ target: String) -> String {
        let all = MenuBarItems.all()
        guard let index = Overflow.match(target, in: all.map { ($0.appName, $0.label) }) else {
            return "No single menu bar icon matches “\(target)”. Run `coatcheck list` to see them."
        }
        let item = all[index]
        return item.press() ? "Opened \(item.appName)." : "\(item.appName) didn’t respond to the click."
    }

    private func applyScreenRule(now: Bool?, previously: Bool?) {
        guard preferences.hideOnLaptopScreen, welcomeObserver == nil,
              let hidden = ScreenRule.hidden(laptopScreenOnly: now, previously: previously) else { return }
        menuBar?.setHidden(hidden, byPerson: false)
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
