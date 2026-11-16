import AppKit
import CoatCheckCore
import PanelKit
import SwiftUI

/// What the Brushed card at the top of the menu reports.
struct MenuCardState {
    /// False until Coat Check has Accessibility access; then nothing can be counted or measured.
    var hasAccess: Bool
    var shown = 0
    var hidden = 0
    /// Share of the icon space the icons fill (`MenuBarSpace.fraction`); nil when it couldn't be measured.
    var fraction: Double?
    /// The divider is folded away, so the icons left of it are hidden on purpose.
    var dividerHiding = false
    /// The main screen has a notch; otherwise the app menus are what crowd the icons.
    var hasNotch = true
}

/// The Brushed card: a metal fascia with a "% used" meter of the menu bar's icon space, and a verdict.
struct CoatCard: View {
    let state: MenuCardState

    var body: some View {
        MenuCard(accent: PanelAccent.coatCheck) {
            if let fraction = state.fraction {
                Fascia(nameplate: "Icons", timestamp: timestamp,
                       detail: state.hasNotch ? "Space before the notch" : "Space beside the app menus", label: "Menu bar") {
                    Meter(
                        MeterConfig(
                            majorTicks: 4, minorTicks: 4, zones: [MenuBarSpace.crowded...1],
                            labels: [.init(0, "0"), .init(0.25, "25"), .init(0.5, "50"), .init(0.75, "75"), .init(1, "100")],
                            word: "% USED", wordSize: 20, accessibilityLabel: "Menu bar space"
                        ),
                        value: fraction, accessibilityValue: Self.spoken(fraction)
                    )
                }
            } else {
                Fascia(nameplate: "Icons", timestamp: timestamp)
            }
            Verdict(title, message: message, status: status, statusLabel: statusLabel)
        }
    }

    private var timestamp: String? {
        state.hasAccess ? "\(state.shown) in the menu bar" : nil
    }

    private var title: String {
        guard state.hasAccess else { return "Needs Accessibility access" }
        guard state.hidden > 0 else { return "Every icon fits in the menu bar" }
        let icons = state.hidden == 1 ? "1 icon" : "\(state.hidden) icons"
        if state.dividerHiding { return "\(icons) hidden" }
        return state.hasNotch ? "\(icons) hidden by the notch" : "\(icons) with no room"
    }

    private var message: String {
        guard state.hasAccess else { return "Coat Check uses it to list and open other apps’ menu bar icons." }
        if state.hidden > 0, state.dividerHiding { return "The divider is hiding the icons to its left. Click one to open it in place." }
        return "Click one to open it in place. Apps with menus open right here."
    }

    private var status: PanelStatus {
        guard state.hasAccess else { return .off }
        return state.hidden > 0 ? .caution : .go
    }

    private var statusLabel: String {
        guard state.hasAccess else { return "No access" }
        return state.hidden > 0 ? "\(state.hidden) hidden" : "All fit"
    }

    static func spoken(_ fraction: Double) -> String {
        let percent = Int((fraction * 100).rounded())
        return percent > 100 ? "Full. The icons need \(percent) percent of the space" : "\(percent) percent used"
    }
}
