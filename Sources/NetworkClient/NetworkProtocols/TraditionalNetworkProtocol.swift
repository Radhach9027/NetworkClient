import Foundation

public protocol RequestProtocol {
    func request(
        for request: NetworkRequestProtocol,
        receive: DispatchQueue,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    )

    func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        receive: DispatchQueue,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) where T: Decodable

   // MARK: DO AGILE BASED ITERATIONS FOR THIS
   /* func serialRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue,
        completion: @escaping (Result<Data?, NetworkError>) -> Void
    )
    
    func concurrentRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue,
        completion: @escaping (Result<[Data?], NetworkError>) -> Void
    )*/
}

/*public protocol UploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    )

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    )
    
    func serialUpload(
         with requests: [NetworkUploadRequestProtocol],
         receive: DispatchQueue,
         completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    )

    func concurrentUpload(
        with requests: [NetworkUploadRequestProtocol],
        receive: DispatchQueue,
        completion: @escaping (Result<[NetworkUploadResponse], NetworkError>) -> Void
    )
}

public protocol DownloadProtocol {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue,
        completion: @escaping (Result<NetworkDownloadResponse, NetworkError>) -> Void
    )
}

public protocol NetworkSessionTaskProtocol {
    func suspend(for request: URLRequest)
    func resume(for request: URLRequest)
    func cancel(for request: URLRequest)
    func cancelAllRequests()
    func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void)
}

public protocol WebSocketProtocol {
    func start(for request: NetworkRequestProtocol, completion: @escaping (Result<Bool, Error>) -> Void)
    func send(message: NetworkSocketMessage, completion: @escaping (Result<Bool, Error>) -> Void)
    func receive(completion: @escaping (Result<NetworkSocketMessage, Error>) -> Void)
    func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: String?,
        completion: @escaping (Result<Bool, Error>) -> Void
    )
}*/

// MARK: Conforming Request, Upload, Download, URLSessionTask, WebSocket to NetworkProtocol as this has been exposed to host app.
@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
public protocol TraditionalNetworkProtocol: RequestProtocol{}
