import Foundation

/// Links the bundled `coatcheck-cli` as `coatcheck` on the PATH, for people who didn't install with Homebrew.
enum CommandLineInstaller {
    private static let homebrew = "/opt/homebrew/bin"
    private static let system = "/usr/local/bin"

    /// Installs the link and describes what happened.
    static func install() -> String {
        guard let tool = Bundle.main.url(forAuxiliaryExecutable: "coatcheck-cli")?.path else {
            return "This copy of Coat Check doesn’t include the command-line tool. Download the latest version from coatcheckformac.com."
        }
        for directory in [homebrew, system] where destination("\(directory)/coatcheck") == tool {
            return "The coatcheck command is already installed at \(directory)/coatcheck. Run `coatcheck --help` in Terminal."
        }
        let manager = FileManager.default
        if manager.isWritableFile(atPath: homebrew) {
            let link = "\(homebrew)/coatcheck"
            if destination(link)?.hasSuffix("/coatcheck-cli") == true {
                try? manager.removeItem(atPath: link)
            } else if manager.fileExists(atPath: link) {
                return "Something else is already installed at \(link), so Coat Check left it alone."
            }
            do {
                try manager.createSymbolicLink(atPath: link, withDestinationPath: tool)
                return "Installed the coatcheck command at \(link). Run `coatcheck --help` in a new Terminal window."
            } catch {
                return "Couldn’t install the coatcheck command: \(error.localizedDescription)"
            }
        }
        let link = "\(system)/coatcheck"
        if manager.fileExists(atPath: link), destination(link) == nil {
            return "Something else is already installed at \(link), so Coat Check left it alone."
        }
        // /usr/local/bin needs an administrator, so macOS asks for a password.
        let command = "mkdir -p \(system) && ln -sfn \(shellQuoted(tool)) \(link)"
        let source = "do shell script \"\(command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            return (error[NSAppleScript.errorNumber] as? Int) == -128
                ? "Didn’t install the coatcheck command."
                : "Couldn’t install the coatcheck command: \(error[NSAppleScript.errorMessage] as? String ?? "unknown error")"
        }
        return "Installed the coatcheck command at \(link). Run `coatcheck --help` in a new Terminal window."
    }

    /// Where a symbolic link points, or nil if the path isn't one.
    private static func destination(_ path: String) -> String? {
        try? FileManager.default.destinationOfSymbolicLink(atPath: path)
    }

    private static func shellQuoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
