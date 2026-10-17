import Foundation

public enum CoatCheckVersion {
    /// The app's marketing version, or "dev" when running outside a bundle.
    public static var current: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}
