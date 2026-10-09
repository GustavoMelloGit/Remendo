import AppKit

/// Ponto de entrada. O Remendo vive só na barra de menus (sem ícone no Dock).
@main
enum RemendoMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
