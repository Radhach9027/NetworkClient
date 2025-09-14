import Foundation

public protocol RequestProtocol {
    func request(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<NetworkSuccessResult<Data>, NetworkError>) -> Void
    )

    func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        completion: @escaping (Result<NetworkSuccessResult<T>, NetworkError>) -> Void
    ) where T: Decodable

    func serialRequests(
        for requests: [NetworkRequestProtocol],
        completion: @escaping (Result<[NetworkSuccessResult<Data>?], NetworkError>) -> Void
    )

    func serialRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        completion: @escaping (Result<[NetworkSuccessResult<T>], NetworkError>) -> Void
    ) where T: Decodable

    func concurrentRequests(
        for requests: [NetworkRequestProtocol],
        individualCompletion: @escaping (Result<NetworkSuccessResult<Data>?, NetworkError>) -> Void,
        finalCompletion: @escaping (Result<[NetworkSuccessResult<Data>?], NetworkError>) -> Void
    )

    func concurrentRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        individualCompletion: @escaping (Result<NetworkSuccessResult<T>, NetworkError>) -> Void,
        finalCompletion: @escaping (Result<[NetworkSuccessResult<T>], NetworkError>) -> Void
    ) where T: Decodable
}

public protocol UploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    )

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    )

    func serialUpload(
        with requests: [NetworkUploadRequestProtocol],
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    )

    func concurrentUpload(
        with requests: [NetworkUploadRequestProtocol],
        completion: @escaping (Result<[NetworkUploadResponse], NetworkError>) -> Void
    )
}

public protocol DownloadProtocol {
    func download(
        for request: NetworkDownloadRequestProtocol,
        completion: @escaping (Result<NetworkDownloadResponse, NetworkError>) -> Void
    )
    
    func downloadSerialRequests(
        for requests: [NetworkDownloadRequestProtocol],
        individualCompletion: @escaping (Result<NetworkDownloadResponse, NetworkError>, Int) -> Void,
        finalCompletion: @escaping () -> Void
    )
    
    func downloadConcurrentRequests(
        for request: [NetworkDownloadRequestProtocol],
        completion: @escaping (Result<[NetworkDownloadResponse], NetworkError>) -> Void
    )
}

public protocol NetworkSessionTaskProtocol {
    func suspend(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    )

    func resume(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    )

    func cancel(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    )

    func cancelRequests(
        for requests: [NetworkRequestProtocol],
        completion: @escaping ([(URL, NetworkError?)]) -> Void
    )

    func cancelAllRequests(
        completion: @escaping ([(URL, NetworkError?)]) -> Void
    )
}

public protocol WebSocketProtocol {
    func start(
        for request: NetworkSocketRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    )
    func send(
        message: Data,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    )
    func receive(completion: @escaping (Result<Data, NetworkError>) -> Void)
    func cancel(completion: @escaping (Result<Bool, NetworkError>) -> Void)
}

public protocol NetworkInterceptorProtocol {
    func add(requestInterceptor: TraditionalNetworkRequestInterceptor)
    func add(retryInterceptor: TraditionalNetworkRetryInterceptor)
}

// MARK: Conforming Request, Upload, Download, SessionTask, Interceptors to NetworkProtocol as this has been exposed to host app.

@available(iOS 11.0, *)
public protocol TraditionalNetworkProtocol:
    RequestProtocol,
    UploadProtocol,
    DownloadProtocol,
    NetworkSessionTaskProtocol,
    NetworkInterceptorProtocol {}
