import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Botão que grava um atalho: clique e aperte as teclas. Esc cancela, ⌫ apaga.
/// Quem usa precisa desligar os atalhos globais enquanto `isRecording` for true,
/// senão eles engolem a tecla antes dela chegar aqui.
struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut?
    @Binding var isRecording: Bool

    @State private var monitor: Any?

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            Text(isRecording ? "Aperte o atalho…" : shortcut?.description ?? "Nenhum")
                .frame(minWidth: 110)
        }
        .onChange(of: isRecording) { recording in
            recording ? start() : stop()
        }
        // Fechar a janela ou trocar de app cancela a gravação.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            isRecording = false
        }
        .onDisappear {
            isRecording = false
            stop()
        }
    }

    private func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch Int(event.keyCode) {
            case kVK_Escape:
                break
            case kVK_Delete:
                shortcut = nil
            default:
                guard let new = Shortcut(event: event) else {
                    NSSound.beep()
                    return nil
                }
                shortcut = new
            }
            isRecording = false
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
