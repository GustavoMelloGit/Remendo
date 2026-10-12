import CoreGraphics

enum Direction: String, CaseIterable, Codable {
    case left, right, up, down
}

/// A geometria do fix, isolada e sem dependência de AppKit pra ser fácil de testar.
/// Tudo em coordenadas do Cocoa: origem no canto inferior esquerdo da tela principal, y pra cima.
enum ScreenRule {
    /// Índice da tela onde está a maior parte da janela.
    static func screen(containing window: CGRect, among screens: [CGRect]) -> Int? {
        let areas = screens.map { area(of: $0.intersection(window)) }
        guard let best = areas.indices.max(by: { areas[$0] < areas[$1] }), areas[best] > 0 else {
            // Janela toda fora das telas: fica com a mais próxima.
            return screens.indices.min { distance(screens[$0], window) < distance(screens[$1], window) }
        }
        return best
    }

    /// Índice da tela mais próxima de `screens[current]` na direção pedida, ou nil se não houver.
    static func neighbor(of current: Int, toward direction: Direction, among screens: [CGRect]) -> Int? {
        let from = screens[current]
        let ahead = screens.indices.filter { $0 != current && advance(from, screens[$0], direction) > 0 }
        let beside = ahead.filter { overlaps(from, screens[$0], across: direction) }
        // Sem tela encostada nesse lado, aceita uma na diagonal, desde que mais pra lá do que pro lado.
        // Assim um monitor à esquerda e um pouco mais alto não conta como "em cima".
        let diagonal = ahead.filter { advance(from, screens[$0], direction) >= sideways(from, screens[$0], direction) }
        return (beside.isEmpty ? diagonal : beside).min { distance(from, screens[$0]) < distance(from, screens[$1]) }
    }

    /// Onde a janela fica na tela nova. Recebe as áreas úteis (sem menu e Dock) das duas telas.
    /// Maximizada continua maximizada; as outras mantêm o tamanho e a posição relativa
    /// (encostada na direita continua encostada na direita, centralizada continua centralizada).
    static func place(_ window: CGRect, from source: CGRect, to target: CGRect) -> CGRect {
        let tolerance: CGFloat = 20
        if window.width >= source.width - tolerance, window.height >= source.height - tolerance {
            return target
        }

        let width = min(window.width, target.width)
        let height = min(window.height, target.height)
        return CGRect(
            x: slide(window.minX, window.width, from: source.minX, source.width, to: target.minX, target.width, width),
            y: slide(window.minY, window.height, from: source.minY, source.height, to: target.minY, target.height, height),
            width: width,
            height: height
        )
    }

    /// Leva a posição num eixo de uma tela pra outra pela fração do espaço livre.
    private static func slide(
        _ position: CGFloat, _ length: CGFloat,
        from sourceStart: CGFloat, _ sourceLength: CGFloat,
        to targetStart: CGFloat, _ targetLength: CGFloat,
        _ newLength: CGFloat
    ) -> CGFloat {
        let room = sourceLength - length
        let fraction = room > 0 ? min(max((position - sourceStart) / room, 0), 1) : 0.5
        return targetStart + fraction * (targetLength - newLength)
    }

    /// Quanto o centro de `to` está à frente do centro de `from` na direção.
    private static func advance(_ from: CGRect, _ to: CGRect, _ direction: Direction) -> CGFloat {
        switch direction {
        case .left: from.midX - to.midX
        case .right: to.midX - from.midX
        case .up: to.midY - from.midY
        case .down: from.midY - to.midY
        }
    }

    /// Quanto o centro de `to` está deslocado pro lado, no eixo que cruza a direção.
    private static func sideways(_ from: CGRect, _ to: CGRect, _ direction: Direction) -> CGFloat {
        switch direction {
        case .left, .right: abs(to.midY - from.midY)
        case .up, .down: abs(to.midX - from.midX)
        }
    }

    /// Se as telas se sobrepõem no eixo que cruza a direção (lado a lado, não na diagonal).
    private static func overlaps(_ a: CGRect, _ b: CGRect, across direction: Direction) -> Bool {
        switch direction {
        case .left, .right: a.minY < b.maxY && b.minY < a.maxY
        case .up, .down: a.minX < b.maxX && b.minX < a.maxX
        }
    }

    private static func distance(_ a: CGRect, _ b: CGRect) -> CGFloat {
        hypot(a.midX - b.midX, a.midY - b.midY)
    }

    private static func area(of rect: CGRect) -> CGFloat {
        rect.isNull ? 0 : rect.width * rect.height
    }
}
