import Sparkle

/// Auto update via Sparkle. O feed (SUFeedURL no Info.plist) aponta pro
/// appcast.xml da última release do GitHub; o CI gera esse arquivo a cada tag.
final class Updater {
    private let controller = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
