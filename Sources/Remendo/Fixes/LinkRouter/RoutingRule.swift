import Foundation

/// Um navegador que está aberto agora.
struct RunningBrowser: Equatable {
    let bundleID: String
    let lastActive: Date?
}

/// A regra de decisão, isolada e sem dependência de AppKit pra ser fácil de testar.
///
/// 1. Nenhum navegador aberto      -> navegador padrão.
/// 2. Exatamente um aberto         -> ele.
/// 3. Mais de um, padrão no meio   -> padrão.
/// 4. Mais de um, padrão fora      -> o usado mais recentemente.
enum RoutingRule {
    static func pick(running: [RunningBrowser], preferred: String?) -> String? {
        let browsers = dedupe(running)

        switch browsers.count {
        case 0:
            return preferred
        case 1:
            return browsers[0].bundleID
        default:
            if let preferred,
               let match = browsers.first(where: { $0.bundleID.lowercased() == preferred.lowercased() }) {
                return match.bundleID
            }
            return browsers
                .max { ($0.lastActive ?? .distantPast) < ($1.lastActive ?? .distantPast) }?
                .bundleID
        }
    }

    /// O mesmo navegador pode ter mais de um processo. Fica com a ativação mais recente.
    private static func dedupe(_ list: [RunningBrowser]) -> [RunningBrowser] {
        var byID: [String: RunningBrowser] = [:]
        var order: [String] = []
        for item in list {
            let key = item.bundleID.lowercased()
            if let existing = byID[key] {
                if (item.lastActive ?? .distantPast) > (existing.lastActive ?? .distantPast) {
                    byID[key] = item
                }
            } else {
                byID[key] = item
                order.append(key)
            }
        }
        return order.compactMap { byID[$0] }
    }
}
