import Foundation

/// How full the menu bar's icon space is: the room between the notch (or the app menus) and the right edge.
public enum MenuBarSpace {
    /// The icons' total width as a share of that room. Above 1 when they need more room than there is; 0 when there is none.
    public static func fraction(widths: [CGFloat], clearFrom: CGFloat, screenMaxX: CGFloat) -> Double {
        let room = screenMaxX - clearFrom
        guard room > 0 else { return 0 }
        return Double(widths.filter { $0 > 0 }.reduce(0, +) / room)
    }

    /// Past this share the meter's red zone starts: one more icon may not fit.
    public static let crowded = 0.85
}
