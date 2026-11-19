#if DEBUG && targetEnvironment(simulator)
import Foundation

/// Client for one OpenCI virtual GATT peer. Call from the main queue.
public final class VirtualBleConnection {
    public enum Event {
        case peerValue(Data), incomingWrite(Data), acknowledged, peerGone
    }

    private var socket: URLSessionWebSocketTask?
    private let onEvent: (Event) -> Void
    private let onError: (Error) -> Void

    public init(endpoint: URL, onEvent: @escaping (Event) -> Void, onError: @escaping (Error) -> Void) throws {
        guard endpoint.scheme == "ws", endpoint.host == "127.0.0.1", ["/A", "/B"].contains(endpoint.path)
        else { throw URLError(.badURL) }
        self.onEvent = onEvent
        self.onError = onError
        let task = URLSession.shared.webSocketTask(with: endpoint)
        socket = task
        task.resume()
        receive(task)
    }

    public func publish(_ value: Data, completion: @escaping (Error?) -> Void) {
        send("card", value: value, completion: completion)
    }

    public func write(_ value: Data, completion: @escaping (Error?) -> Void) {
        send("write", value: value, completion: completion)
    }

    public func acknowledge(completion: @escaping (Error?) -> Void) {
        send("reply", value: nil, completion: completion)
    }

    public func close() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
    }

    private func send(_ type: String, value: Data?, completion: @escaping (Error?) -> Void) {
        guard let socket else { completion(URLError(.notConnectedToInternet)); return }
        var frame = ["type": type]
        frame["value"] = value?.base64EncodedString()
        do {
            let data = try JSONEncoder().encode(frame)
            socket.send(.data(data)) { error in DispatchQueue.main.async { completion(error) } }
        } catch { completion(error) }
    }

    private func receive(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.socket === task else { return }
                do {
                    let data: Data
                    switch try result.get() {
                    case .string(let text): data = Data(text.utf8)
                    case .data(let bytes): data = bytes
                    @unknown default: throw URLError(.cannotDecodeContentData)
                    }
                    let frame = try JSONDecoder().decode([String: String].self, from: data)
                    switch frame["type"] {
                    case "peer", "incoming":
                        guard let value = frame["value"].flatMap({ Data(base64Encoded: $0) })
                        else { throw URLError(.cannotDecodeContentData) }
                        self.onEvent(frame["type"] == "peer" ? .peerValue(value) : .incomingWrite(value))
                    case "accepted": self.onEvent(.acknowledged)
                    case "gone": self.onEvent(.peerGone)
                    default: throw URLError(.cannotDecodeContentData)
                    }
                    self.receive(task)
                } catch {
                    self.close()
                    self.onError(error)
                }
            }
        }
    }
}
#endif
