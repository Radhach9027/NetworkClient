import Foundation

@available(iOS 11.0, *)
public protocol URLSessionTraditionalProtocol {
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask
    
    func uploadTask(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTask
    
    func uploadTask(
        with request: URLRequest,
        fromFile fileURL: URL,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTask

    func downloadTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (URL?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDownloadTask
    
    func getTasksWithCompletionHandler(
        _ completionHandler: @escaping @Sendable (
            [URLSessionDataTask],
            [URLSessionUploadTask],
            [URLSessionDownloadTask]
        ) -> Void
    )
    
    func downloadTask(with request: URLRequest) -> URLSessionDownloadTask
    
    func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void)
}


@available(iOS 11.0, *)
extension URLSession: URLSessionTraditionalProtocol {}
