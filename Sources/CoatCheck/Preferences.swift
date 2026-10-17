import Foundation
import CoatCheckCore

/// Settings people can change, saved in UserDefaults.
final class Preferences: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var autoHideDelay: AutoHideDelay {
        didSet { defaults.set(autoHideDelay.rawValue, forKey: "autoHideDelay") }
    }

    init() {
        autoHideDelay = AutoHideDelay(rawValue: defaults.integer(forKey: "autoHideDelay")) ?? .never
    }
}
