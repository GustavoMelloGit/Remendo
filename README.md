# Remendo

App de barra de menus pro macOS com correções pequenas do dia a dia.
Requer macOS 13 ou mais novo.

## Fixes

### 1. Roteador de links

Quando você clica num link em qualquer app, o Remendo decide pra qual navegador ele vai:

1. Nenhum navegador aberto → abre no seu navegador padrão.
2. Só um aberto → abre nele.
3. Mais de um aberto e o padrão está entre eles → abre no padrão.
4. Mais de um aberto e o padrão não está → abre no que você usou por último.

Pra isso funcionar, o Remendo vira o "navegador" do sistema e repassa cada link.
O seu navegador padrão de verdade fica guardado dentro do Remendo (menu → Roteador de links… → Navegador padrão).

### 2. Mover entre telas

⌥⌘ + seta manda a janela da frente pra tela vizinha naquela direção.
Janela maximizada continua maximizada; as outras mantêm o tamanho e a posição relativa na tela.
Os atalhos mudam em menu → Mover entre telas….

Precisa da permissão de Acessibilidade, que o Remendo pede no primeiro uso.
Como o app é assinado ad hoc, a permissão se perde a cada build ou atualização:
nos Ajustes do Sistema, remova o Remendo da lista (−) e permita de novo.

## Instalar

```bash
chmod +x build.sh
./build.sh install
```

Depois, no ícone de curativo na barra de menus, abra **Roteador de links…**:

1. Confira o **Navegador padrão** (ele pega o atual do sistema na primeira vez).
2. Clique em **Receber os links…** e confirme as duas janelas do macOS.

Cada fix tem a sua página na janela de ajustes. Ela também abre quando você abre o Remendo de novo pelo Finder ou Spotlight.

Pra desfazer: Ajustes do Sistema → Área de Trabalho e Dock → Navegador padrão.

## Atualizações

O app se atualiza sozinho via [Sparkle](https://sparkle-project.org), lendo o `appcast.xml` da última release.
Todo push na `main` passa pelo semantic-release, e a versão sai do tipo dos commits:

- `fix: ...` → patch (0.2.1 → 0.2.2)
- `feat: ...` → minor (0.2.1 → 0.3.0)
- `feat!: ...` ou `BREAKING CHANGE:` no corpo → major (0.2.1 → 1.0.0)

Outros tipos (`chore:`, `docs:`, `refactor:`...) não geram release.

O workflow `.github/workflows/release.yml` roda o `scripts/package-release.sh`, que compila, assina o zip com a chave EdDSA (secret `SPARKLE_PRIVATE_KEY`)
e publica a release. A chave privada também fica no Keychain (conta `remendo` do `generate_keys` do Sparkle).

## Adicionar um fix novo

1. Crie uma pasta em `Sources/Remendo/Fixes/<NomeDoFix>/`.
2. Faça uma classe que conforma com `Fix` (`Sources/Remendo/Core/Fix.swift`).
   O `settingsView()` devolve as seções (`Section`) da página do fix na janela de ajustes.
3. Registre ela em `AppDelegate.fixes`. Ela ganha um item no menu e uma página na barra lateral.
4. Regra de decisão vai num `<Nome>Rule.swift` sem AppKit, com testes em `Tests/RemendoTests/`.

## Testes

```bash
swift test
```

Rodam em todo PR (`.github/workflows/check.yml`) e antes de cada release.

## Estrutura

```
Sources/Remendo/
├── RemendoApp.swift          ponto de entrada
├── AppDelegate.swift         barra de menus e recebimento de links
├── Core/
│   ├── Fix.swift               protocolo dos fixes + ActionMenuItem
│   ├── SettingsWindow.swift    janela de ajustes (barra lateral com os fixes)
│   ├── Settings.swift          preferências (UserDefaults)
│   ├── Caption.swift           título + explicação, usado nas páginas de ajustes
│   ├── Shortcut.swift          atalho de teclado (tecla + modificadores)
│   ├── ShortcutRecorder.swift  botão que grava um atalho
│   ├── HotKeys.swift           atalhos globais (Carbon)
│   └── Updater.swift           auto update (Sparkle)
└── Fixes/
    ├── LinkRouter/
    │   ├── BrowserCatalog.swift          navegadores instalados
    │   ├── BrowserActivityTracker.swift  qual foi usado por último
    │   ├── RoutingRule.swift             a regra de decisão
    │   ├── LinkRouterSettingsView.swift  página de ajustes
    │   └── LinkRouterFix.swift           junta tudo
    └── WindowMover/
        ├── ScreenRule.swift              tela vizinha e onde a janela fica nela
        ├── AXWindow.swift                lê e move a janela (Acessibilidade)
        ├── WindowMoverSettingsView.swift página de ajustes
        └── WindowMoverFix.swift          junta tudo
Tests/RemendoTests/           testes das regras (Swift Testing)
Support/Info.plist            registra http/https
build.sh                      monta o Remendo.app
scripts/package-release.sh    zip assinado + appcast.xml (usado pelo semantic-release)
.releaserc.json               config do semantic-release
```
