import Foundation

/// Preferências do Remendo, guardadas no UserDefaults.
enum Settings {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let preferredBrowser = "linkRouter.preferredBrowserBundleID"
        static let routerEnabled = "linkRouter.enabled"
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
}
