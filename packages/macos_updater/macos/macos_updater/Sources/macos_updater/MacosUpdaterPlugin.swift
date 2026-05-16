import Cocoa
import FlutterMacOS
import Sparkle

public class MacosUpdaterPlugin: NSObject, FlutterPlugin, MacosUpdaterHostApi, SPUUpdaterDelegate {
  private var feedUrlString: String?

  override public init() {
    super.init()
    _ = updaterController
  }

  private lazy var updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: self,
      userDriverDelegate: nil
    )

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MacosUpdaterPlugin()
    MacosUpdaterHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func setFeedUrl(url: String) throws {
    guard let feedUrl = URL(string: url) else {
      throw PigeonError(
        code: "invalid-feed-url",
        message: "The update feed URL is invalid.",
        details: url
      )
    }
    feedUrlString = feedUrl.absoluteString
  }

  func checkForUpdates() throws {
    updaterController.checkForUpdates(nil)
  }

  func setScheduledCheckInterval(seconds: Int64) throws {
    updaterController.updater.updateCheckInterval = TimeInterval(seconds)
  }

  public func feedURLString(for updater: SPUUpdater) -> String? {
    return feedUrlString
  }
}
