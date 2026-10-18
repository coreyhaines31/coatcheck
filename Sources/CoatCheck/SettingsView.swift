import Combine
import ServiceManagement
import SwiftUI
import CoatCheckCore

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    var checkForUpdates: () -> Void
    @State private var commandLineNote: String?
    @State private var trusted = MenuBarItems.isTrusted
    /// Accessibility has no change notification, so check while the window is open.
    private let trustPoll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "hanger")
                        .font(.system(size: 28))
                        .foregroundStyle(.tint)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Every menu bar icon, within reach").font(.headline)
                        Text("When the notch or a crowded menu bar leaves no room, macOS quietly hides icons. "
                             + "Click the hanger to see every one and open any of them.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility")
                        Text(trusted ? "On. Coat Check can list and open menu bar icons."
                                     : "Needed to list and open other apps’ menu bar icons. Coat Check reads nothing else.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if trusted {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button("Allow…") {
                            MenuBarItems.requestAccess()
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
            }
            Section {
                Toggle(isOn: $preferences.useDivider) {
                    Text("Hide icons with a divider")
                    Text("Adds a │ divider left of the hanger. Icons to its left can be hidden to clear space. "
                         + "Hold ⌘ and drag icons across it.")
                }
                if preferences.useDivider {
                    Toggle(isOn: $preferences.hideOnLaptopScreen) {
                        Text("Hide them on the laptop screen")
                        Text("Hides them when the built-in display is the only one, and shows them again when an external display connects.")
                    }
                    Picker("After showing them, hide them again", selection: $preferences.autoHideDelay) {
                        ForEach(AutoHideDelay.allCases) { delay in Text(delay.title).tag(delay) }
                    }
                }
            }
            Section {
                Toggle("Open Coat Check at login", isOn: Binding(
                    get: { preferences.launchesAtLogin },
                    set: { preferences.setLaunchAtLogin($0) }
                ))
                if preferences.loginStatus == .requiresApproval {
                    Button("Approve in Login Items…") { SMAppService.openSystemSettingsLoginItems() }
                }
                if let notice = preferences.notice {
                    Text(notice).font(.callout).foregroundStyle(.secondary)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Command line")
                        Text(commandLineNote ?? "List and open menu bar icons from Terminal or an AI agent with the coatcheck command.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Install…") { commandLineNote = CommandLineInstaller.install() }
                }
            }
            Section {
                HStack {
                    Text("Coat Check \(CoatCheckVersion.current)").foregroundStyle(.secondary)
                    Spacer()
                    Button("Check for Updates…", action: checkForUpdates)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { preferences.refreshLoginStatus() }
        .onReceive(trustPoll) { _ in trusted = MenuBarItems.isTrusted }
    }
}
