import AppKit

/// Ícone da barra de menus: um band-aid sólido na diagonal, com vãos separando a almofada.
/// Em monitor 1x qualquer desenho girado fica borrado, então o 1x é pixel art feita à mão;
/// o 2x é vetor com o mesmo formato.
enum MenuBarIcon {
    // Tamanho ímpar: o centro cai num pixel e os furinhos formam um quadrado certinho.
    private static let size = NSSize(width: 17, height: 17)

    /// Versão 1x, um caractere por pixel ("#" = preenchido).
    private static let pixels = [
        "............####.",
        "...........######",
        "..........#######",
        "..........#######",
        "........#..######",
        ".......###..####.",
        "......#####..##..",
        ".....##.#.##.....",
        "....#########....",
        ".....##.#.##.....",
        "..##..#####......",
        ".####..###.......",
        "######..#........",
        "#######..........",
        "#######..........",
        "######...........",
        ".####............",
    ]

    static func make() -> NSImage {
        let image = NSImage(size: size)
        image.addRepresentation(pixelArt())
        image.addRepresentation(vector())
        image.isTemplate = true
        image.accessibilityDescription = "Remendo"
        return image
    }

    private static func bitmap(scale: Int) -> NSBitmapImageRep {
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
        return rep
    }

    private static func pixelArt() -> NSBitmapImageRep {
        let rep = bitmap(scale: 1)
        let data = rep.bitmapData!
        for (y, row) in pixels.enumerated() {
            for (x, pixel) in row.enumerated() where pixel == "#" {
                // Template só olha o alpha.
                data[y * rep.bytesPerRow + x * 4 + 3] = 255
            }
        }
        return rep
    }

    private static func vector() -> NSBitmapImageRep {
        let rep = bitmap(scale: 2)
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        NSColor.black.set()

        // Fita na horizontal, centrada na origem e girada 45°.
        let center = size.width / 2
        let rotation = NSAffineTransform()
        rotation.translateX(by: center, yBy: center)
        rotation.rotate(byDegrees: 45)
        rotation.concat()
        NSBezierPath(roundedRect: NSRect(x: -11.3, y: -3.5, width: 22.6, height: 7), xRadius: 3.5, yRadius: 3.5).fill()

        // Vãos entre a almofada e as pontas.
        context.compositingOperation = .clear
        NSRect(x: -4.4, y: -7, width: 1, height: 14).fill()
        NSRect(x: 3.4, y: -7, width: 1, height: 14).fill()

        // Furinhos alinhados à tela, como no 1x.
        rotation.invert()
        rotation.concat()
        for x in [center - 1.5, center + 0.5] {
            for y in [center - 1.5, center + 0.5] {
                NSRect(x: x, y: y, width: 1, height: 1).fill()
            }
        }

        NSGraphicsContext.restoreGraphicsState()
        return rep
    }
}
