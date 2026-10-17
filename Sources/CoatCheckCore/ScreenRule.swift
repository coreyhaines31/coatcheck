/// Decides whether icons should be checked based on which displays are in use.
public enum ScreenRule {
    /// True when every screen is built in, where the notch leaves little room. Nil when no screens are
    /// reported, which happens briefly during sleep and display changes and says nothing either way.
    public static func laptopScreenOnly(builtIn screens: [Bool]) -> Bool? {
        guard !screens.isEmpty else { return nil }
        return !screens.contains(false)
    }

    /// What to do after a display change: hide on the laptop screen alone, show once an external display is in use.
    /// Nil leaves the person's choice alone, since nothing that matters changed.
    public static func hidden(laptopScreenOnly now: Bool?, previously: Bool?) -> Bool? {
        guard let now, now != previously else { return nil }
        return now
    }
}
