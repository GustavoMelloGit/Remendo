import AppKit
import SwiftUI

/// Cada "remendo" do app implementa este protocolo.
/// Pra adicionar um fix novo: crie uma classe que conforma com `Fix`
/// e registre ela em `AppDelegate.fixes`.
protocol Fix: AnyObject {
    /// Nome que aparece no menu e na barra lateral da janela de ajustes.
    var title: String { get }

    /// SF Symbol do fix.
    var symbol: String { get }

    /// Uma frase explicando o que o fix faz. Aparece no topo dos ajustes.
    var summary: String { get }

    /// Seções (`Section`) com os ajustes do fix. A janela embrulha tudo num `Form`.
    func settingsView() -> AnyView

    /// Chamado uma vez quando o app termina de iniciar.
    func start()
}

extension Fix {
    func start() {}
}

/// NSMenuItem que executa uma closure. Evita espalhar @objc selectors pelo código.
final class ActionMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) não é usado")
    }

    @objc private func fire() {
        handler()
    }
}
