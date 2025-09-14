import Combine
import Foundation

@available(iOS 13.0, *)
public protocol URLSessionWebSocketTaskProtocol {
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void)
    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
    func sendPing(pongReceiveHandler: @escaping @Sendable (Error?) -> Void)
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
    func cancel()
    func suspend()
    func resume()
}

@available(iOS 13.0, *)
extension URLSessionWebSocketTask: URLSessionWebSocketTaskProtocol {}
