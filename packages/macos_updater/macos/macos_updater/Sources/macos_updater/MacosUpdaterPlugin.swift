import Cocoa
import FlutterMacOS
import Sparkle

public class MacosUpdaterPlugin: NSObject, FlutterPlugin, MacosUpdaterHostApi, SPUUpdaterDelegate, FlutterStreamHandler {
  private var feedUrlString: String?
  private var eventSink: FlutterEventSink?
  private var isWaitingForManualCheckResult = false

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
    let eventChannel = FlutterEventChannel(
      name: "macos_updater/events",
      binaryMessenger: registrar.messenger
    )
    eventChannel.setStreamHandler(instance)
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
    isWaitingForManualCheckResult = true
    updaterController.checkForUpdates(nil)
  }

  func setScheduledCheckInterval(seconds: Int64) throws {
    updaterController.updater.updateCheckInterval = TimeInterval(seconds)
  }

  public func feedURLString(for updater: SPUUpdater) -> String? {
    return feedUrlString
  }

  public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
    completeManualCheck(
      type: "updateAvailable",
      message: "Update available.",
      version: item.versionString,
      displayVersion: item.displayVersionString
    )
  }

  public func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
    completeManualCheck(
      type: "noUpdateFound",
      message: error.localizedDescription
    )
  }

  public func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
    completeManualCheck(
      type: "failed",
      message: error.localizedDescription
    )
  }

  private func completeManualCheck(
    type: String,
    message: String,
    version: String? = nil,
    displayVersion: String? = nil
  ) {
    guard isWaitingForManualCheckResult else {
      return
    }

    isWaitingForManualCheckResult = false
    var payload: [String: Any] = [
      "type": type,
      "message": message
    ]
    if let version = version {
      payload["version"] = version
    }
    if let displayVersion = displayVersion {
      payload["displayVersion"] = displayVersion
    }
    eventSink?(payload)
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
