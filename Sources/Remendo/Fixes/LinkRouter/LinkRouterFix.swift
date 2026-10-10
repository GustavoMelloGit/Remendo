import AppKit
import SwiftUI
import os

/// Fix 1: manda cada link pro navegador que faz sentido, não sempre pro padrão.
final class LinkRouterFix: Fix {
    let title = "Roteador de links"
    let symbol = "arrow.triangle.branch"
    let summary = "Manda cada link pro navegador que faz sentido, não sempre pro padrão."

    private let tracker = BrowserActivityTracker()
    private let log = Logger(subsystem: "com.gustavo.remendo", category: "LinkRouter")

    func start() {
        // Primeira execução: o padrão atual do sistema vira o "padrão" do Remendo.
        if Settings.preferredBrowserBundleID == nil,
           let current = BrowserCatalog.systemDefaultBrowser() {
            Settings.preferredBrowserBundleID = current.bundleID
        }
    }

    // MARK: - Roteamento

    func route(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        let preferred = Settings.preferredBrowserBundleID ?? BrowserCatalog.safariBundleID
        let target: String

        if Settings.linkRouterEnabled {
            target = RoutingRule.pick(running: runningBrowsers(), preferred: preferred) ?? preferred
        } else {
            target = preferred
        }

        open(urls, in: target, fallback: preferred)
    }

    private func runningBrowsers() -> [RunningBrowser] {
        let installedIDs = Set(BrowserCatalog.installed().map { $0.bundleID.lowercased() })

        return NSWorkspace.shared.runningApplications.compactMap { app in
            guard
                app.activationPolicy == .regular,
                !app.isTerminated,
                let id = app.bundleIdentifier,
                installedIDs.contains(id.lowercased())
            else { return nil }
            return RunningBrowser(bundleID: id, lastActive: tracker.lastActive(app))
        }
    }

    private func open(_ urls: [URL], in bundleID: String, fallback: String) {
        let appURL = BrowserCatalog.appURL(for: bundleID)
            ?? BrowserCatalog.appURL(for: fallback)
            ?? BrowserCatalog.appURL(for: BrowserCatalog.safariBundleID)

        guard let appURL else {
            log.error("Nenhum navegador encontrado pra abrir o link")
            NSSound.beep()
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        log.info("Abrindo \(urls.count) link(s) em \(bundleID, privacy: .public)")
        NSWorkspace.shared.open(urls, withApplicationAt: appURL, configuration: config) { [log] _, error in
            if let error {
                log.error("Falha ao abrir: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Ajustes

    func settingsView() -> AnyView {
        AnyView(LinkRouterSettingsView(fix: self))
    }

    /// Pede ao macOS pra usar o Remendo como navegador do sistema.
    /// O macOS mostra uma janela de confirmação pra cada esquema.
    /// `done` roda na main thread quando o macOS termina de responder.
    func becomeSystemDefault(done: @escaping () -> Void) {
        // Garante que o padrão atual fique salvo antes de trocar.
        if Settings.preferredBrowserBundleID == nil,
           let current = BrowserCatalog.systemDefaultBrowser() {
            Settings.preferredBrowserBundleID = current.bundleID
        }

        let me = Bundle.main.bundleURL
        let finish = { DispatchQueue.main.async(execute: done) }
        NSWorkspace.shared.setDefaultApplication(at: me, toOpenURLsWithScheme: "http") { [log] error in
            if let error {
                log.error("http: \(error.localizedDescription, privacy: .public)")
                finish()
                return
            }
            NSWorkspace.shared.setDefaultApplication(at: me, toOpenURLsWithScheme: "https") { error in
                if let error {
                    log.error("https: \(error.localizedDescription, privacy: .public)")
                }
                finish()
            }
        }
    }
}
