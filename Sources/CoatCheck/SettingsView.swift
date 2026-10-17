import ServiceManagement
import SwiftUI
import CoatCheckCore

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    var checkForUpdates: () -> Void
    @State private var commandLineNote: String?

    var body: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "hanger")
                        .font(.system(size: 28))
                        .foregroundStyle(.tint)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Check the icons you don’t need right now").font(.headline)
                        Text("Icons to the left of the │ divider get checked. Hold ⌘ and drag the ones "
                             + "you always want to see to the right of it, next to the hanger.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Click the hanger to check icons or get them back. Right-click it for settings.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section {
                Toggle(isOn: $preferences.hideOnLaptopScreen) {
                    Text("Check icons on the laptop screen")
                    Text("The notch leaves little room when the built-in display is the only one. "
                         + "Coat Check checks icons then and brings them back when an external display connects.")
                }
                Picker("After showing icons, check them again", selection: $preferences.autoHideDelay) {
                    ForEach(AutoHideDelay.allCases) { delay in Text(delay.title).tag(delay) }
                }
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
            }
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Command line")
                        Text(commandLineNote ?? "Check and show icons from Terminal or an AI agent with the coatcheck command.")
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
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { preferences.refreshLoginStatus() }
    }
}
