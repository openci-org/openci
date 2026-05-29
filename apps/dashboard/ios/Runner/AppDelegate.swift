import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "org.openci.dashboard/app_control",
                                        binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "installAndMinimize" {
          guard let args = call.arguments as? [String: Any],
                let urlString = args["url"] as? String,
                let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "URL is required", details: nil))
            return
          }
          
          UIApplication.shared.open(url, options: [:]) { success in
            if success {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let selector = NSSelectorFromString("suspend")
                if UIApplication.shared.responds(to: selector) {
                  UIApplication.shared.perform(selector)
                }
              }
              result(true)
            } else {
              result(false)
            }
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
