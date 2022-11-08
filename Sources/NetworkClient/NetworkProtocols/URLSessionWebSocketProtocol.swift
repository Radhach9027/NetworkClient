import Foundation

public protocol URLSessionWebSocketProtocol {
    func webSocketTask(with url: URL) -> URLSessionWebSocketTask
    func webSocketTask(with url: URL, protocols: [String]) -> URLSessionWebSocketTask
    func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTask
}
