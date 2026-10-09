import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let updater = Updater()

    // Registre fixes novos aqui.
    private let linkRouter = LinkRouterFix()
    private lazy var fixes: [Fix] = [linkRouter]

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Roda antes de qualquer link chegar, inclusive quando o app
        // é aberto a frio por um clique num link.
        fixes.forEach { $0.start() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "bandage", accessibilityDescription: "Remendo")
            ?? NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: "Remendo")
        item.button?.image?.isTemplate = true

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    /// O macOS chama isto quando um link http/https é aberto e o Remendo é o navegador padrão.
    func application(_ application: NSApplication, open urls: [URL]) {
        linkRouter.route(urls)
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        for fix in fixes {
            let header = NSMenuItem(title: fix.title, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            fix.menuItems().forEach { menu.addItem($0) }
            menu.addItem(.separator())
        }

        let login = ActionMenuItem("Abrir ao iniciar sessão") {
            Self.toggleLaunchAtLogin()
        }
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(ActionMenuItem("Procurar atualizações…") { [updater] in
            updater.checkForUpdates()
        })

        menu.addItem(ActionMenuItem("Sair do Remendo", key: "q") {
            NSApp.terminate(nil)
        })
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
