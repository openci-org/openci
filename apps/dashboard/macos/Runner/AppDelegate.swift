import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private lazy var deepLinkChannel: FlutterMethodChannel? = {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return nil
    }
    return FlutterMethodChannel(
      name: "org.openci.dashboard/deep_link",
      binaryMessenger: controller.engine.binaryMessenger
    )
  }()

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func application(
    _ application: NSApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
