import Foundation

@available(iOS 13.0, *)
public protocol URLSessionWebSocketProtocol {
    func webSocketTask(with url: URL) -> URLSessionWebSocketTaskProtocol
    func webSocketTask(with url: URL, protocols: [String]) -> URLSessionWebSocketTaskProtocol
    func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTaskProtocol
}

@available(iOS 13.0, *)
extension URLSession: URLSessionWebSocketProtocol {
    public func webSocketTask(with url: URL) -> URLSessionWebSocketTaskProtocol {
        return (self.webSocketTask(with: url) as URLSessionWebSocketTask)
    }

    public func webSocketTask(with url: URL, protocols: [String]) -> URLSessionWebSocketTaskProtocol {
        return (self.webSocketTask(with: url, protocols: protocols) as URLSessionWebSocketTask)
    }

    public func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTaskProtocol {
        return (self.webSocketTask(with: request) as URLSessionWebSocketTask)
    }
}
