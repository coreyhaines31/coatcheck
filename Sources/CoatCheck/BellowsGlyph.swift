import AppKit

/// The menu bar glyph: a bellows between two end plates, drawn from mac-app-kit `Scripts/glyphs/glyphs.mjs` (`coat`).
/// Folded when the icons left of the divider are hidden (or there is no divider), opened out when they show.
enum BellowsGlyph {
    static let folded = make(open: false)
    static let open = make(open: true)

    private static func make(open: Bool) -> NSImage {
        // 18 pt square in SVG coordinates (y down), one ink with the folds knocked out.
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            let folds = open ? 4 : 2
            let x0: CGFloat = open ? 3.2 : 6.2
            let x1: CGFloat = open ? 14.8 : 11.8
            let width = (x1 - x0) / CGFloat(folds)
            NSColor.black.setFill()
            for x in [x0 - 2.4, x1 + 0.3] {
                NSBezierPath(roundedRect: NSRect(x: x, y: 2.5, width: 2.1, height: 13), xRadius: 0.8, yRadius: 0.8).fill()
            }
            let body = NSBezierPath()
            body.move(to: NSPoint(x: x0, y: 4.2))
            for fold in 0..<folds {
                let start = x0 + CGFloat(fold) * width
                body.line(to: NSPoint(x: start + width / 2, y: 7.4))
                body.line(to: NSPoint(x: start + width, y: 4.2))
            }
            for fold in (0..<folds).reversed() {
                let start = x0 + CGFloat(fold) * width
                body.line(to: NSPoint(x: start + width, y: 13.8))
                body.line(to: NSPoint(x: start + width / 2, y: 10.6))
            }
            body.line(to: NSPoint(x: x0, y: 13.8))
            body.close()
            body.fill()
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            for fold in 1..<folds {
                NSRect(x: x0 + CGFloat(fold) * width - 0.4, y: 3, width: 0.8, height: 12).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Coat Check"
        return image
    }
}
