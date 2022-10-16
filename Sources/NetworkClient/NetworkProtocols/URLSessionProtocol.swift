import Foundation

public protocol URLSessionProtocol {
    
    func dataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher
    
    func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher
    
    func downloadTask(with request: URLRequest) -> URLSessionDownloadTask
    
    func downloadTask(with url: URL) -> URLSessionDownloadTask
    
    func getAllTasks(completionHandler: @escaping ([URLSessionTask]) -> Void)
    
    func invalidateAndCancel()
}

extension URLSession: URLSessionProtocol {}
