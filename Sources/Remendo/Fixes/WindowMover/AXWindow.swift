import AppKit
import ApplicationServices

/// Janela de outro app, mexida pela API de Acessibilidade.
/// O macOS só libera isso com a permissão de Acessibilidade (Ajustes do Sistema → Privacidade e Segurança).
struct AXWindow {
    private let window: AXUIElement
    private let app: AXUIElement

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Mostra o pedido de permissão do macOS, que tem o botão pra abrir os Ajustes do Sistema.
    static func requestAccess() {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    /// A janela em foco do app da frente.
    static func focused() -> AXWindow? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        let app = AXUIElementCreateApplication(pid)
        guard let window = app.attribute(kAXFocusedWindowAttribute),
              CFGetTypeID(window) == AXUIElementGetTypeID()
        else { return nil }
        return AXWindow(window: window as! AXUIElement, app: app)
    }

    /// Tela cheia de verdade vive num Space próprio e não dá pra mover.
    var isFullScreen: Bool {
        window.attribute("AXFullScreen") as? Bool ?? false
    }

    /// Posição e tamanho em coordenadas do Cocoa.
    var frame: CGRect? {
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard let position = window.axValue(kAXPositionAttribute),
              let dimensions = window.axValue(kAXSizeAttribute),
              AXValueGetValue(position, .cgPoint, &origin),
              AXValueGetValue(dimensions, .cgSize, &size)
        else { return nil }
        return Self.flip(CGRect(origin: origin, size: size))
    }

    func setFrame(_ frame: CGRect) {
        // Com isso ligado (Chrome, apps Electron), o app anima cada mudança e às vezes ignora o tamanho.
        let enhanced = app.attribute("AXEnhancedUserInterface") as? Bool ?? false
        if enhanced { app.set("AXEnhancedUserInterface", kCFBooleanFalse) }
        defer { if enhanced { app.set("AXEnhancedUserInterface", kCFBooleanTrue) } }

        var origin = Self.flip(frame).origin
        var size = frame.size
        guard let position = AXValueCreate(.cgPoint, &origin),
              let dimensions = AXValueCreate(.cgSize, &size)
        else { return }

        // Primeiro leva pra tela nova, onde o tamanho novo cabe. Redimensionar pode
        // empurrar a janela, então a posição vai de novo no fim.
        window.set(kAXPositionAttribute, position)
        window.set(kAXSizeAttribute, dimensions)
        window.set(kAXPositionAttribute, position)
    }

    /// A Acessibilidade usa y pra baixo a partir do topo da tela principal; o Cocoa, y pra cima
    /// a partir da base. A conta é a mesma nos dois sentidos.
    private static func flip(_ rect: CGRect) -> CGRect {
        let height = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: rect.minX, y: height - rect.maxY, width: rect.width, height: rect.height)
    }
}

private extension AXUIElement {
    func attribute(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success else { return nil }
        return value
    }

    func axValue(_ name: String) -> AXValue? {
        guard let value = attribute(name), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue)
    }

    func set(_ name: String, _ value: CFTypeRef) {
        AXUIElementSetAttributeValue(self, name as CFString, value)
    }
}
