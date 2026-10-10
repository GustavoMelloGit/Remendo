import AppKit

/// Ícone da barra de menus: um band-aid na diagonal, desenhado à mão.
/// Os SF Symbols de band-aid ficam borrados em monitor 1x e o status item
/// achata os que passam de 16pt, então geramos as versões 1x e 2x direto em pixel.
enum MenuBarIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        for scale in [1, 2] {
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(size.width) * scale,
                pixelsHigh: Int(size.height) * scale,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )!
            rep.size = size
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            // Em 1x vira pixel art: sem antialias o degrau de 45° fica nítido.
            draw(in: size, pixelArt: scale == 1)
            NSGraphicsContext.restoreGraphicsState()
            image.addRepresentation(rep)
        }
        image.isTemplate = true
        image.accessibilityDescription = "Remendo"
        return image
    }

    private static func draw(in size: NSSize, pixelArt: Bool) {
        let context = NSGraphicsContext.current!
        context.shouldAntialias = !pixelArt

        // Desenha o band-aid na horizontal, centrado na origem, e gira 45°.
        let transform = NSAffineTransform()
        transform.translateX(by: size.width / 2, yBy: size.height / 2)
        transform.rotate(byDegrees: 45)
        transform.concat()

        NSColor.black.set()
        let strip = NSBezierPath(roundedRect: NSRect(x: -10.25, y: -3.75, width: 20.5, height: 7.5), xRadius: 3.75, yRadius: 3.75)
        strip.lineWidth = pixelArt ? 1 : 1.5
        strip.stroke()
        NSBezierPath(roundedRect: NSRect(x: -3.5, y: -3.75, width: 7, height: 7.5), xRadius: 0.5, yRadius: 0.5).fill()

        // Furinhos da almofada.
        context.compositingOperation = .clear
        for (x, y) in [(-1.75, -1.75), (0.75, -1.75), (-1.75, 0.75), (0.75, 0.75)] {
            NSRect(x: x, y: y, width: 1, height: 1).fill()
        }
    }
}
