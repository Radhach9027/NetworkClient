import Foundation

public protocol URLSessionProtocol: URLSessionWebSocketProtocol {
    func dataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher
    func downloadTask(with request: URLRequest) -> URLSessionDownloadTask
    func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask
    func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask
    func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void)
    func flush(completionHandler: @escaping @Sendable () -> Void)
}

extension URLSession: URLSessionProtocol {}
