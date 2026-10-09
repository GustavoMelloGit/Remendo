import AppKit

struct Browser: Hashable {
    let bundleID: String
    let name: String
    let appURL: URL

    var icon: NSImage {
        let image = NSWorkspace.shared.icon(forFile: appURL.path)
        image.size = NSSize(width: 16, height: 16)
        return image
    }
}

/// Descobre quais navegadores estão instalados e qual é o padrão do sistema.
enum BrowserCatalog {
    static let ownBundleID = (Bundle.main.bundleIdentifier ?? "com.gustavo.remendo").lowercased()
    static let safariBundleID = "com.apple.Safari"

    private static let probeURL = URL(string: "https://example.com")!

    /// Todo app que se declara capaz de abrir https, menos o próprio Remendo.
    static func installed() -> [Browser] {
        var seen = Set<String>()
        return NSWorkspace.shared.urlsForApplications(toOpen: probeURL)
            .compactMap { browser(at: $0) }
            .filter { seen.insert($0.bundleID.lowercased()).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// O app que o macOS usa hoje pra abrir links (pode ser o próprio Remendo).
    static func systemDefaultAppURL() -> URL? {
        NSWorkspace.shared.urlForApplication(toOpen: probeURL)
    }

    /// O navegador padrão do sistema, ignorando o Remendo.
    static func systemDefaultBrowser() -> Browser? {
        systemDefaultAppURL().flatMap { browser(at: $0) }
    }

    static func isRemendoSystemDefault() -> Bool {
        guard let url = systemDefaultAppURL(),
              let id = Bundle(url: url)?.bundleIdentifier else { return false }
        return id.lowercased() == ownBundleID
    }

    static func appURL(for bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    private static func browser(at appURL: URL) -> Browser? {
        guard let id = Bundle(url: appURL)?.bundleIdentifier,
              id.lowercased() != ownBundleID else { return nil }
        var name = FileManager.default.displayName(atPath: appURL.path)
        if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
        return Browser(bundleID: id, name: name, appURL: appURL)
    }
}
