import AppKit

/// Anota quando cada app foi ativado (veio pra frente) pela última vez.
/// É assim que sabemos qual navegador foi o "mais recente".
final class BrowserActivityTracker {
    private var lastActivation: [String: Date] = [:]
    private var observer: NSObjectProtocol?

    init() {
        if let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            lastActivation[front.lowercased()] = Date()
        }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                let id = app.bundleIdentifier
            else { return }
            self?.lastActivation[id.lowercased()] = Date()
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    /// Última ativação vista desde que o Remendo abriu.
    /// Se o app nunca foi ativado nesse tempo, usa a hora em que ele foi aberto.
    func lastActive(_ app: NSRunningApplication) -> Date? {
        guard let id = app.bundleIdentifier?.lowercased() else { return nil }
        return lastActivation[id] ?? app.launchDate
    }
}
