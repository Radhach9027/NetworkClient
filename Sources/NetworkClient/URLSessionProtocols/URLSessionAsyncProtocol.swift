import Foundation

@available(iOS 15.0, *)
public protocol URLSessionAsyncProtocol {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    func upload(for request: URLRequest, fromFile fileURL: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    func upload(for request: URLRequest, from bodyData: Data, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    func download(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (URL, URLResponse)
}

extension URLSession: URLSessionAsyncProtocol {}
