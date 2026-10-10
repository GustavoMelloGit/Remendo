import AppKit
import SwiftUI

/// Ajustes do roteador de links, mostrados na janela de ajustes.
struct LinkRouterSettingsView: View {
    let fix: LinkRouterFix

    @AppStorage(Settings.Key.routerEnabled) private var routerEnabled = true
    @AppStorage(Settings.Key.preferredBrowser) private var preferredBrowser: String?

    @State private var browsers: [Browser] = []
    @State private var isReceivingLinks = false

    var body: some View {
        Group {
            Section {
                Toggle(isOn: $routerEnabled) {
                    Caption("Abrir no navegador que já está aberto",
                            detail: "Desligado, todo link vai pro navegador padrão.")
                }

                if browsers.isEmpty {
                    LabeledContent("Navegador padrão", value: "Nenhum navegador encontrado")
                } else {
                    Picker(selection: $preferredBrowser) {
                        ForEach(browsers, id: \.bundleID) { browser in
                            Label {
                                Text(browser.name)
                            } icon: {
                                Image(nsImage: browser.icon)
                            }
                            .tag(Optional(browser.bundleID))
                        }
                    } label: {
                        Caption("Navegador padrão",
                                detail: "Pro sistema, o navegador passa a ser o Remendo. O seu fica guardado aqui.")
                    }
                }
            }

            Section("Navegador do sistema") {
                if isReceivingLinks {
                    Label {
                        Text("O Remendo está recebendo os links")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                } else {
                    LabeledContent {
                        Button("Receber os links…") {
                            fix.becomeSystemDefault { refresh() }
                        }
                    } label: {
                        Caption("O Remendo não está recebendo os links",
                                detail: "Sem isso, os links vão direto pro navegador do sistema.")
                    }
                }
            }

            if routerEnabled {
                Section("Pra onde vai cada link") {
                    LabeledContent("Nenhum navegador aberto", value: "Navegador padrão")
                    LabeledContent("Só um aberto", value: "Ele mesmo")
                    LabeledContent("Vários, e o padrão é um deles", value: "Navegador padrão")
                    LabeledContent("Vários, sem o padrão", value: "O usado por último")
                }
            }
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // O usuário pode ter trocado o navegador nos Ajustes do Sistema.
            refresh()
        }
    }

    private func refresh() {
        browsers = BrowserCatalog.installed()
        isReceivingLinks = BrowserCatalog.isRemendoSystemDefault()
    }
}

/// Título com uma linha de explicação embaixo.
private struct Caption: View {
    let title: String
    let detail: String

    init(_ title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
