import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Fix 2: um atalho manda a janela da frente pra tela vizinha, na direção da seta.
final class WindowMoverFix: Fix {
    let title = "Mover entre telas"
    let symbol = "display.2"
    let summary = "Um atalho manda a janela da frente pra tela vizinha, na direção da seta."

    static let defaultShortcuts: [Direction: Shortcut] = [
        .left: Shortcut(keyCode: kVK_LeftArrow, modifiers: [.command, .option], key: "←"),
        .right: Shortcut(keyCode: kVK_RightArrow, modifiers: [.command, .option], key: "→"),
        .up: Shortcut(keyCode: kVK_UpArrow, modifiers: [.command, .option], key: "↑"),
        .down: Shortcut(keyCode: kVK_DownArrow, modifiers: [.command, .option], key: "↓"),
    ]

    private let hotKeys = HotKeys()

    /// Fica true enquanto a página de ajustes grava um atalho, pra tecla chegar no gravador.
    var isPaused = false {
        didSet { registerHotKeys() }
    }

    func start() {
        registerHotKeys()
    }

    /// Relê os ajustes e registra os atalhos de novo.
    func registerHotKeys() {
        guard Settings.windowMoverEnabled, !isPaused else {
            hotKeys.set([])
            return
        }
        hotKeys.set(Settings.windowMoverShortcuts.map { direction, shortcut in
            (shortcut, { [weak self] in self?.moveFocusedWindow(direction) })
        })
    }

    // MARK: - Mover

    func moveFocusedWindow(_ direction: Direction) {
        guard AXWindow.isTrusted else {
            AXWindow.requestAccess()
            return
        }
        guard let window = AXWindow.focused(), !window.isFullScreen, let frame = window.frame else { return }

        let screens = NSScreen.screens
        let frames = screens.map(\.frame)
        guard let source = ScreenRule.screen(containing: frame, among: frames),
              let target = ScreenRule.neighbor(of: source, toward: direction, among: frames)
        else { return }

        window.setFrame(ScreenRule.place(frame, from: screens[source].visibleFrame, to: screens[target].visibleFrame))
    }

    // MARK: - Ajustes

    func settingsView() -> AnyView {
        AnyView(WindowMoverSettingsView(fix: self))
    }
}
