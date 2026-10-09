import AppKit

/// Cada "remendo" do app implementa este protocolo.
/// Pra adicionar um fix novo: crie uma classe que conforma com `Fix`
/// e registre ela em `AppDelegate.fixes`.
protocol Fix: AnyObject {
    /// Nome que aparece como seção no menu.
    var title: String { get }

    /// Itens de menu do fix. Chamado toda vez que o menu abre,
    /// então pode refletir o estado atual.
    func menuItems() -> [NSMenuItem]

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
