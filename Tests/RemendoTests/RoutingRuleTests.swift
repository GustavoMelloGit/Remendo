import Foundation
import Testing
@testable import Remendo

private let safari = "com.apple.Safari"
private let chrome = "com.google.Chrome"
private let firefox = "org.mozilla.firefox"

private func running(_ bundleID: String, at seconds: TimeInterval) -> RunningBrowser {
    RunningBrowser(bundleID: bundleID, lastActive: Date(timeIntervalSince1970: seconds))
}

struct RoutingRuleTests {
    @Test("nenhum navegador aberto: vai pro padrão")
    func noneRunning() {
        #expect(RoutingRule.pick(running: [], preferred: safari) == safari)
    }

    @Test("só um aberto: vai pra ele")
    func oneRunning() {
        #expect(RoutingRule.pick(running: [running(chrome, at: 1)], preferred: safari) == chrome)
    }

    @Test("vários, e o padrão é um deles: vai pro padrão")
    func preferredAmongRunning() {
        let browsers = [running(chrome, at: 2), running("com.apple.safari", at: 1)]
        #expect(RoutingRule.pick(running: browsers, preferred: safari) == "com.apple.safari")
    }

    @Test("vários, sem o padrão: vai pro usado por último")
    func mostRecent() {
        let browsers = [running(chrome, at: 1), running(firefox, at: 2)]
        #expect(RoutingRule.pick(running: browsers, preferred: safari) == firefox)
    }

    @Test("processos do mesmo navegador contam como um só")
    func dedupesProcesses() {
        #expect(RoutingRule.pick(running: [running(chrome, at: 1), running(chrome, at: 3)], preferred: safari) == chrome)

        // Fica com a ativação mais recente de cada navegador.
        let browsers = [running(chrome, at: 1), running(firefox, at: 2), running(chrome, at: 3)]
        #expect(RoutingRule.pick(running: browsers, preferred: safari) == chrome)
    }
}
