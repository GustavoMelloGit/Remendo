import AppKit
import Carbon.HIToolbox

/// Tecla + modificadores de um atalho global.
struct Shortcut: Codable, Equatable {
    let keyCode: UInt32
    /// `NSEvent.ModifierFlags.rawValue`, só com ⌃ ⌥ ⇧ ⌘.
    let modifiers: UInt
    /// Nome da tecla guardado na gravação ("←", "K"), pra não depender do layout do teclado.
    let key: String

    private static let allowedFlags: NSEvent.ModifierFlags = [.control, .option, .shift, .command]

    init(keyCode: Int, modifiers: NSEvent.ModifierFlags, key: String) {
        self.keyCode = UInt32(keyCode)
        self.modifiers = modifiers.intersection(Self.allowedFlags).rawValue
        self.key = key
    }

    /// Atalho a partir de uma tecla apertada. Precisa de ⌃, ⌥ ou ⌘, senão roubaria a tecla de todo app.
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(Self.allowedFlags)
        guard !flags.isDisjoint(with: [.control, .option, .command]) else { return nil }
        let key = Self.specialKeys[Int(event.keyCode)]
            ?? event.charactersIgnoringModifiers?.uppercased()
            ?? ""
        guard !key.isEmpty else { return nil }
        self.init(keyCode: Int(event.keyCode), modifiers: flags, key: key)
    }

    var flags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    /// Os mesmos modificadores no formato do `RegisterEventHotKey`.
    var carbonModifiers: UInt32 {
        var carbon = 0
        if flags.contains(.control) { carbon |= controlKey }
        if flags.contains(.option) { carbon |= optionKey }
        if flags.contains(.shift) { carbon |= shiftKey }
        if flags.contains(.command) { carbon |= cmdKey }
        return UInt32(carbon)
    }

    /// Do jeito que o macOS mostra nos menus: "⌥⌘←".
    var description: String {
        var text = ""
        if flags.contains(.control) { text += "⌃" }
        if flags.contains(.option) { text += "⌥" }
        if flags.contains(.shift) { text += "⇧" }
        if flags.contains(.command) { text += "⌘" }
        return text + key
    }

    /// Teclas cujo caractere não serve pra mostrar.
    private static let specialKeys: [Int: String] = [
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Return: "↩", kVK_Tab: "⇥", kVK_Space: "Espaço", kVK_ForwardDelete: "⌦",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]
}
