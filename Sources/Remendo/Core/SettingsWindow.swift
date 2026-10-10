import AppKit
import SwiftUI

/// Janela de ajustes: barra lateral com os fixes e, ao lado, os ajustes do selecionado.
final class SettingsWindow {
    private let fixes: [Fix]
    private let navigation = SettingsNavigation()
    private var window: NSWindow?

    init(fixes: [Fix]) {
        self.fixes = fixes
    }

    /// Abre a janela (ou traz pra frente) mostrando `fix`, ou o último visto.
    func show(_ fix: Fix? = nil) {
        if let fix {
            navigation.selection = fix.title
        } else if navigation.selection == nil {
            navigation.selection = fixes.first?.title
        }

        let window = self.window ?? makeWindow()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let root = SettingsView(fixes: fixes, navigation: navigation)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = "Remendo"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbar = NSToolbar()
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 720, height: 560))
        window.center()
        window.setFrameAutosaveName("Ajustes")
        return window
    }
}

/// Qual fix está selecionado na barra lateral.
private final class SettingsNavigation: ObservableObject {
    @Published var selection: String?
}

private struct SettingsView: View {
    let fixes: [Fix]
    @ObservedObject var navigation: SettingsNavigation

    private var selected: Fix? {
        fixes.first { $0.title == navigation.selection }
    }

    var body: some View {
        NavigationSplitView {
            List(fixes, id: \.title, selection: $navigation.selection) { fix in
                Label(fix.title, systemImage: fix.symbol)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            if let fix = selected {
                Form {
                    FixHeader(fix: fix)
                    fix.settingsView()
                }
                .formStyle(.grouped)
            }
        }
        .frame(minWidth: 640, minHeight: 460)
    }
}

/// Topo dos ajustes de cada fix, no estilo dos Ajustes do Sistema.
private struct FixHeader: View {
    let fix: Fix

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: fix.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(fix.title)
                        .font(.headline)
                    Text(fix.summary)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
