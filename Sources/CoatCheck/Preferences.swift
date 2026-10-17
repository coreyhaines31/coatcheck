import Foundation
import ServiceManagement
import CoatCheckCore

/// Settings people can change, saved in UserDefaults.
final class Preferences: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var autoHideDelay: AutoHideDelay {
        didSet { defaults.set(autoHideDelay.rawValue, forKey: "autoHideDelay") }
    }
    /// Checks icons whenever only the built-in display is in use, and brings them back with an external one.
    @Published var hideOnLaptopScreen: Bool {
        didSet { defaults.set(hideOnLaptopScreen, forKey: "hideOnLaptopScreen") }
    }
    @Published private(set) var loginStatus = SMAppService.mainApp.status
    @Published var notice: String?

    init() {
        autoHideDelay = AutoHideDelay(rawValue: defaults.integer(forKey: "autoHideDelay")) ?? .never
        hideOnLaptopScreen = defaults.object(forKey: "hideOnLaptopScreen") as? Bool ?? true
    }

    /// True until the person has seen the welcome once.
    var isFirstLaunch: Bool { !defaults.bool(forKey: "hasLaunched") }

    func markLaunched() { defaults.set(true, forKey: "hasLaunched") }

    var launchesAtLogin: Bool { loginStatus == .enabled || loginStatus == .requiresApproval }

    func refreshLoginStatus() { loginStatus = SMAppService.mainApp.status }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginStatus = SMAppService.mainApp.status
            notice = loginStatus == .requiresApproval
                ? "Allow Coat Check in System Settings → General → Login Items to finish turning on launch at login."
                : nil
        } catch {
            loginStatus = SMAppService.mainApp.status
            notice = "Couldn’t change launch at login: \(error.localizedDescription)"
        }
    }

    /// Turns on launch at login the first time an installed copy runs. Only once, so turning it off sticks.
    func applyLaunchAtLoginDefault() {
        #if !DEBUG
        guard !defaults.bool(forKey: "appliedLaunchAtLoginDefault"),
              Bundle.main.bundlePath.contains("/Applications/") else { return }
        try? SMAppService.mainApp.register()
        loginStatus = SMAppService.mainApp.status
        if loginStatus == .enabled || loginStatus == .requiresApproval {
            defaults.set(true, forKey: "appliedLaunchAtLoginDefault")
        }
        #endif
    }
}
