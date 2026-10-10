import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let updater = Updater()

    // Registre fixes novos aqui.
    private let linkRouter = LinkRouterFix()
    private lazy var fixes: [Fix] = [linkRouter]
    private lazy var settingsWindow = SettingsWindow(fixes: fixes)

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Roda antes de qualquer link chegar, inclusive quando o app
        // é aberto a frio por um clique num link.
        fixes.forEach { $0.start() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = MenuBarIcon.make()

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item

        NSApp.mainMenu = Self.makeMainMenu()
    }

    /// Abrir o Remendo de novo (Finder, Spotlight) mostra a janela de ajustes.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show()
        return false
    }

    /// O macOS chama isto quando um link http/https é aberto e o Remendo é o navegador padrão.
    func application(_ application: NSApplication, open urls: [URL]) {
        linkRouter.route(urls)
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Cada fix abre a janela de ajustes direto na página dele.
        for fix in fixes {
            let item = ActionMenuItem("\(fix.title)…") { [weak self] in
                self?.settingsWindow.show(fix)
            }
            item.image = NSImage(systemSymbolName: fix.symbol, accessibilityDescription: nil)
            menu.addItem(item)
        }
        menu.addItem(.separator())

        let login = ActionMenuItem("Abrir ao iniciar sessão") {
            Self.toggleLaunchAtLogin()
        }
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(ActionMenuItem("Procurar atualizações…") { [updater] in
            updater.checkForUpdates()
        })

        menu.addItem(ActionMenuItem("Sair", key: "q") {
            NSApp.terminate(nil)
        })
    }

    /// Não aparece (o app não tem Dock), mas é ele que faz ⌘W e ⌘Q funcionarem na janela.
    private static func makeMainMenu() -> NSMenu {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Fechar janela", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        appMenu.addItem(withTitle: "Sair", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        let main = NSMenu()
        main.addItem(appItem)
        return main
    }

    private static func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
        }
    }
}
