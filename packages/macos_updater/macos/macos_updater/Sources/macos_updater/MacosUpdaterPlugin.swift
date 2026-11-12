import Cocoa
import FlutterMacOS
import Sparkle

public class MacosUpdaterPlugin: NSObject, FlutterPlugin, MacosUpdaterHostApi, SPUUpdaterDelegate, FlutterStreamHandler {
  private var feedUrlString: String?
  private var eventSink: FlutterEventSink?
  private var isWaitingForManualCheckResult = false
  private var isStarted = false

  private lazy var updaterController = SPUStandardUpdaterController(
      startingUpdater: false,
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

  func start() throws {
    guard !isStarted else { return }
    try updaterController.updater.start()
    isStarted = true
  }

  func setFeedUrl(url: String) throws {
    guard let feedUrl = URL(string: url),
          feedUrl.scheme == "https",
          feedUrl.host != nil,
          feedUrl.user == nil,
          feedUrl.password == nil,
          feedUrl.fragment == nil else {
      throw PigeonError(
        code: "invalid-feed-url",
        message: "The update feed must be an HTTPS URL without credentials or a fragment.",
        details: nil
      )
    }
    feedUrlString = feedUrl.absoluteString
  }

  func checkForUpdates() throws {
    try start()
    guard updaterController.updater.canCheckForUpdates else {
      throw PigeonError(code: "check-unavailable", message: "An update check is already in progress.", details: nil)
    }
    isWaitingForManualCheckResult = true
    updaterController.checkForUpdates(nil)
  }

  func setScheduledCheckInterval(seconds: Int64) throws {
    updaterController.updater.updateCheckInterval = TimeInterval(seconds)
  }

  public func feedURLString(for updater: SPUUpdater) -> String? {
    return feedUrlString ?? Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String
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
