import Flutter
import UIKit

@objc(AppMinimizerPlusPlugin)
public class AppMinimizerPlusPlugin: NSObject, FlutterPlugin, AppMinimizerHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let api = AppMinimizerPlusPlugin()
    AppMinimizerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
  }

  public func minimize() throws {
    DispatchQueue.main.async {
      UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
  }
}
