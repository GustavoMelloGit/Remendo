import Foundation

/// Preferências do Remendo, guardadas no UserDefaults.
enum Settings {
    private static let defaults = UserDefaults.standard

    /// Também usadas pelo `@AppStorage` das telas de ajustes.
    enum Key {
        static let preferredBrowser = "linkRouter.preferredBrowserBundleID"
        static let routerEnabled = "linkRouter.enabled"
        static let windowMoverEnabled = "windowMover.enabled"
        static let windowMoverShortcuts = "windowMover.shortcuts"
    }

    /// O navegador "padrão" do ponto de vista do usuário.
    /// O padrão do sistema passa a ser o próprio Remendo, então guardamos
    /// aqui qual navegador de verdade ele considera o principal.
    static var preferredBrowserBundleID: String? {
        get { defaults.string(forKey: Key.preferredBrowser) }
        set { defaults.set(newValue, forKey: Key.preferredBrowser) }
    }

    /// Quando desligado, todo link vai direto pro navegador padrão.
    static var linkRouterEnabled: Bool {
        get { defaults.object(forKey: Key.routerEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.routerEnabled) }
    }

    /// Quando desligado, os atalhos de mover janela voltam pros outros apps.
    static var windowMoverEnabled: Bool {
        get { defaults.object(forKey: Key.windowMoverEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.windowMoverEnabled) }
    }

    /// Atalho de cada direção. Direção fora do dicionário não tem atalho.
    static var windowMoverShortcuts: [Direction: Shortcut] {
        get {
            guard let data = defaults.data(forKey: Key.windowMoverShortcuts),
                  let saved = try? JSONDecoder().decode([Direction: Shortcut].self, from: data)
            else { return WindowMoverFix.defaultShortcuts }
            return saved
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: Key.windowMoverShortcuts) }
    }
}
