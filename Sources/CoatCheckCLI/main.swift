import AppKit
import CoatCheckCore

let help = """
coatcheck: reach every menu bar icon, even the ones the notch hides.

Usage: coatcheck <command> [--json]

Commands:
  list      Every menu bar icon, with the ones macOS had no room for marked hidden
  click <name>
            Open a menu bar icon, even one macOS had no room for
  status    Whether the divider is hiding icons, and whether only the laptop screen is in use
  hide      Hide the icons left of the divider (when the divider is on)
  show      Show them again
  toggle    Hide them if they're showing, show them if they're hidden
  open      Open Coat Check, or its settings if it's already running

Options:
  --json    Machine-readable output
  -h, --help
  -v, --version

Every command except open needs Coat Check running. list and click also need
Accessibility permission for Coat Check (System Settings → Privacy & Security).
<name> is an app name from `coatcheck list` (any case; the start works when it's
unique), or "App: label" when an app has several icons.

Exit codes: 0 success, 1 error or Coat Check isn't running,
2 hiding refused because the divider sits right of the hanger.

More: https://github.com/coreyhaines31/coatcheck#command-line
"""

var json = false
var command = ""
var target: [String] = []
for argument in CommandLine.arguments.dropFirst() {
    switch argument {
    case "--json": json = true
    case "-h", "--help": command = "help"
    case "-v", "--version": command = "version"
    default:
        guard !argument.hasPrefix("-") else { fail("Unknown option \(argument). Run `coatcheck --help`.") }
        if command.isEmpty { command = argument } else { target.append(argument) }
    }
}

func printJSON<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) { print(text) }
}

func fail(_ message: String, code: Int32 = 1) -> Never {
    if json { printJSON(["error": message]) } else { FileHandle.standardError.write(Data((message + "\n").utf8)) }
    exit(code)
}

/// Reads the version from the app bundle this tool ships in, following the Homebrew or PATH symlink.
func bundledVersion() -> String {
    let executable = Bundle.main.executableURL?.resolvingSymlinksInPath()
    let plist = executable?.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Info.plist")
    let info = plist.flatMap { NSDictionary(contentsOf: $0) }
    return info?["CFBundleShortVersionString"] as? String ?? "dev"
}

func send(_ action: Command.Action, target: String = "") -> Command.Reply {
    guard !NSRunningApplication.runningApplications(withBundleIdentifier: Command.bundleIdentifier).isEmpty else {
        fail("Coat Check isn't running. Start it with `coatcheck open`.")
    }
    let request = Command.Request(action: action, target: target)
    var reply: Command.Reply?
    let center = DistributedNotificationCenter.default()
    let observer = center.addObserver(forName: Command.reply, object: nil, queue: .main) { notification in
        if let received = Command.Reply(userInfo: notification.userInfo), received.id == request.id { reply = received }
    }
    center.postNotificationName(Command.request, object: nil, userInfo: request.userInfo, deliverImmediately: true)
    let deadline = Date().addingTimeInterval(3)
    while reply == nil, Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
    center.removeObserver(observer)
    guard let reply else { fail("Coat Check didn't answer. Try again, or restart it.") }
    return reply
}

func needAccessibility() -> Never {
    fail("Coat Check needs Accessibility permission to see other apps' menu bar icons. "
         + "Turn it on in System Settings → Privacy & Security → Accessibility.")
}

func report(_ reply: Command.Reply) {
    if json { return printJSON(reply) }
    if let message = reply.message { return print(message) }
    print(reply.accessibility ? "Accessibility is on, so Coat Check can list and open every menu bar icon."
                              : "Accessibility is off. Turn it on in System Settings → Privacy & Security → Accessibility.")
    guard reply.divider else { return print("The divider is off, so Coat Check isn't hiding any icons.") }
    print(reply.hidden ? "Icons left of the divider are hidden." : "Icons left of the divider are showing.")
    switch (reply.laptopScreenOnly, reply.hideOnLaptopScreen) {
    case (true, true): print("Only the laptop screen is in use, so Coat Check hides them automatically.")
    case (false, true): print("An external display is in use, so Coat Check leaves them showing.")
    case (true, false): print("Only the laptop screen is in use. Hiding automatically there is off.")
    default: break
    }
    if !reply.dividerPlaced {
        print("The divider sits right of the hanger, so icons can't be hidden. Hold ⌘ and drag it left of the hanger.")
    }
}

switch command {
case "", "help": print(help)
case "version": json ? printJSON(["version": bundledVersion()]) : print("coatcheck \(bundledVersion())")
case "open":
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Command.bundleIdentifier) else {
        fail("Coat Check isn't installed. Download it from https://coatcheckformac.com.")
    }
    var opened = false
    NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
        if let error { fail("Couldn’t open Coat Check: \(error.localizedDescription)") }
        opened = true
    }
    while !opened { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
case "list":
    let reply = send(.list)
    guard reply.accessibility else { needAccessibility() }
    let items = reply.items ?? []
    if json { printJSON(items) } else {
        for item in items {
            let name = Overflow.displayName(app: item.app, label: item.label)
            print("\(item.visible ? "  " : "* ")\(name.name)\(name.detail.map { " (\($0))" } ?? "")")
        }
        print("\n* hidden: macOS had no room for it. Open one with `coatcheck click <name>`.")
    }
case "click":
    guard !target.isEmpty else { fail("Name an icon: `coatcheck click <name>`. See them with `coatcheck list`.") }
    let reply = send(.click, target: target.joined(separator: " "))
    guard reply.accessibility else { needAccessibility() }
    let message = reply.message ?? ""
    if json { printJSON(["message": message]) } else { print(message) }
    if !message.hasPrefix("Opened") { exit(1) }
case "status": report(send(.status))
case "show": report(send(.show))
case "toggle": report(send(.toggle))
case "hide":
    let reply = send(.hide)
    report(reply)
    if reply.message != nil { exit(1) }
    if !reply.hidden { exit(2) }
default: fail("Unknown command \(command). Run `coatcheck --help`.")
}
