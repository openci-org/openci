import Flutter
import Foundation

public final class OpenciVirtualBlePlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    #if DEBUG && targetEnvironment(simulator)
    private var connection: VirtualBleConnection?
    #endif

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "org.openci/virtual_ble", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(OpenciVirtualBlePlugin(channel: channel), channel: channel)
    }

    private init(channel: FlutterMethodChannel) { self.channel = channel }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if DEBUG && targetEnvironment(simulator)
        let finish: (Error?) -> Void = { error in
            if let error { result(FlutterError(code: "gatt", message: error.localizedDescription, details: nil)) }
            else { result(nil) }
        }
        switch call.method {
        case "connect":
            guard connection == nil, let address = call.arguments as? String, let url = URL(string: address)
            else { finish(URLError(.badURL)); return }
            do {
                connection = try VirtualBleConnection(endpoint: url, onEvent: { [weak self] event in
                    switch event {
                    case .peerValue(let value): self?.channel.invokeMethod("peer", arguments: FlutterStandardTypedData(bytes: value))
                    case .incomingWrite(let value): self?.channel.invokeMethod("incoming", arguments: FlutterStandardTypedData(bytes: value))
                    case .acknowledged: self?.channel.invokeMethod("accepted", arguments: nil)
                    case .peerGone: self?.channel.invokeMethod("gone", arguments: nil)
                    }
                }, onError: { [weak self] error in
                    self?.connection = nil
                    self?.channel.invokeMethod("disconnected", arguments: error.localizedDescription)
                })
                result(nil)
            } catch { finish(error) }
        case "card", "write":
            guard let connection, let value = call.arguments as? FlutterStandardTypedData
            else { result(FlutterError(code: "value", message: "Expected a connected peer and bytes", details: nil)); return }
            if call.method == "card" { connection.publish(value.data, completion: finish) }
            else { connection.write(value.data, completion: finish) }
        case "reply":
            guard let connection else { finish(URLError(.notConnectedToInternet)); return }
            connection.acknowledge(completion: finish)
        case "close":
            connection?.close()
            connection = nil
            result(nil)
        default: result(FlutterMethodNotImplemented)
        }
        #else
        if call.method == "close" { result(nil) }
        else { result(FlutterError(code: "unsupported", message: "Requires a Debug iOS Simulator", details: nil)) }
        #endif
    }
}
