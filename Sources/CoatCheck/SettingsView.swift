import ServiceManagement
import SwiftUI
import CoatCheckCore

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    var checkForUpdates: () -> Void

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
                        Text("Hold ⌘ and drag menu bar icons to the left of the │ divider. "
                             + "Click the hanger to check them, and click it again to get them back.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Right-click the hanger for settings and updates.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section {
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
