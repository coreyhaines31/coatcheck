import AppKit
import CoatCheckCore

/// Reports whether only the built-in display is in use, after display changes settle.
final class ScreenWatcher {
    private var observer: NSObjectProtocol?
    private var pending: DispatchWorkItem?
    private(set) var laptopScreenOnly: Bool?
    var onChange: ((_ now: Bool?, _ previously: Bool?) -> Void)?

    func start() {
        laptopScreenOnly = Self.read()
        observer = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                                          object: nil, queue: .main) { [weak self] _ in self?.screensChanged() }
    }

    /// Connecting a display sends a burst of notifications, so wait a moment for the final arrangement.
    private func screensChanged() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let previously = laptopScreenOnly
            let now = Self.read()
            if now != nil { laptopScreenOnly = now }
            onChange?(now, previously)
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
    }

    static func read() -> Bool? {
        ScreenRule.laptopScreenOnly(builtIn: NSScreen.screens.map { screen in
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return number.map { CGDisplayIsBuiltin($0) != 0 } ?? false
        })
    }
}
