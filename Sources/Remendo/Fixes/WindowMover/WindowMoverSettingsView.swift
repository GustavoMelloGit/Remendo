import AppKit
import SwiftUI

/// Ajustes do "mover entre telas", mostrados na janela de ajustes.
struct WindowMoverSettingsView: View {
    let fix: WindowMoverFix

    @AppStorage(Settings.Key.windowMoverEnabled) private var enabled = true

    @State private var shortcuts = Settings.windowMoverShortcuts
    @State private var recording: Direction?
    @State private var isTrusted = AXWindow.isTrusted

    var body: some View {
        Group {
            Section {
                Toggle(isOn: $enabled) {
                    Caption("Mover com atalho",
                            detail: "Enquanto ligado, esses atalhos não chegam nos outros apps.")
                }
            }

            Section("Acessibilidade") {
                if isTrusted {
                    Label {
                        Text("O Remendo pode mover as janelas")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                } else {
                    LabeledContent {
                        Button("Permitir…") {
                            AXWindow.requestAccess()
                        }
                    } label: {
                        Caption("O Remendo não pode mover as janelas",
                                detail: "Se ele já aparece ligado lá, remova (−) e permita de novo. Acontece depois de atualizar.")
                    }
                }
            }

            Section {
                ForEach(Direction.allCases, id: \.self) { direction in
                    LabeledContent(direction.screenName) {
                        ShortcutRecorder(shortcut: shortcut(for: direction), isRecording: isRecording(direction))
                    }
                }
            } header: {
                Text("Atalhos")
            } footer: {
                HStack {
                    Text("Clique e aperte o atalho. Esc cancela, ⌫ apaga.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Restaurar padrões") {
                        save(WindowMoverFix.defaultShortcuts)
                    }
                }
            }
            .disabled(!enabled)
        }
        .onChange(of: enabled) { _ in
            fix.registerHotKeys()
        }
        .onChange(of: recording) { direction in
            fix.isPaused = direction != nil
        }
        .onDisappear {
            fix.isPaused = false
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // A permissão é dada nos Ajustes do Sistema, fora daqui.
            refresh()
        }
    }

    private func shortcut(for direction: Direction) -> Binding<Shortcut?> {
        Binding {
            shortcuts[direction]
        } set: { new in
            // Cada atalho move pra uma direção só.
            var updated = shortcuts.filter { $0.value != new }
            updated[direction] = new
            save(updated)
        }
    }

    private func isRecording(_ direction: Direction) -> Binding<Bool> {
        Binding {
            recording == direction
        } set: { on in
            if on {
                recording = direction
            } else if recording == direction {
                recording = nil
            }
        }
    }

    private func save(_ new: [Direction: Shortcut]) {
        shortcuts = new
        Settings.windowMoverShortcuts = new
        fix.registerHotKeys()
    }

    private func refresh() {
        isTrusted = AXWindow.isTrusted
    }
}

private extension Direction {
    var screenName: String {
        switch self {
        case .left: "Tela da esquerda"
        case .right: "Tela da direita"
        case .up: "Tela de cima"
        case .down: "Tela de baixo"
        }
    }
}
