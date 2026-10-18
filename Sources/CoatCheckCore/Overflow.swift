import CoreGraphics

/// Finding the menu bar icons macOS had no room for, and picking one by name.
public enum Overflow {
    /// macOS shows only the icons that fit between the app menus (or the notch) and the right edge.
    /// `clearFrom` is the first x where icons can show: the notch's right edge, or the end of the app menus.
    public static func isVisible(_ item: CGRect, clearFrom: CGFloat, screenMaxX: CGFloat) -> Bool {
        item.width > 0 && item.minX >= clearFrom && item.maxX <= screenMaxX + 1
    }

    /// Finds the icon a name refers to: an app name, or "App: label" when an app has several.
    /// Exact matches win over prefixes; ambiguity returns nil.
    public static func match(_ target: String, in items: [(app: String, label: String)]) -> Int? {
        let wanted = target.lowercased().trimmingCharacters(in: .whitespaces)
        guard !wanted.isEmpty else { return nil }
        let names = items.map { (app: $0.app.lowercased(), full: "\($0.app): \($0.label)".lowercased()) }
        for test in [{ (name: (app: String, full: String)) in name.full == wanted || name.app == wanted },
                     { (name: (app: String, full: String)) in name.full.hasPrefix(wanted) || name.app.hasPrefix(wanted) }] {
            let found = names.indices.filter { test(names[$0]) }
            if found.count == 1 { return found[0] }
            if found.count > 1 {
                // Several icons from one app: the first is usually its main one.
                return Set(found.map { names[$0].app }).count == 1 ? found[0] : nil
            }
        }
        return nil
    }
}
