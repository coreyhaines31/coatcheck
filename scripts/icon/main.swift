import AppKit

// Renders Coat Check's app icon: the hanger symbol on a ticket-red tile.
let directory = CommandLine.arguments[1]
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = Double(size * scale)
        let image = NSImage(size: NSSize(width: pixels, height: pixels), flipped: false) { bounds in
            // macOS icon grid: an 824-point rounded square centered on a 1024-point canvas.
            let tile = bounds.insetBy(dx: pixels * 100 / 1024, dy: pixels * 100 / 1024)
            let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.2237, yRadius: tile.width * 0.2237)
            NSGradient(starting: NSColor(srgbRed: 0.851, green: 0.247, blue: 0.247, alpha: 1),
                       ending: NSColor(srgbRed: 0.6, green: 0.106, blue: 0.133, alpha: 1))?.draw(in: shape, angle: -90)
            let configuration = NSImage.SymbolConfiguration(pointSize: tile.width * 0.5, weight: .semibold)
                .applying(.init(paletteColors: [.white]))
            if let hanger = NSImage(systemSymbolName: "hanger", accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration) {
                let width = tile.width * 0.62
                let height = width * hanger.size.height / hanger.size.width
                hanger.draw(in: NSRect(x: tile.midX - width / 2, y: tile.midY - height / 2, width: width, height: height))
            }
            return true
        }
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(pixels), pixelsHigh: Int(pixels),
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        if let data = bitmap.representation(using: .png, properties: [:]) {
            try data.write(to: URL(fileURLWithPath: directory + "/icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"))
        }
    }
}
