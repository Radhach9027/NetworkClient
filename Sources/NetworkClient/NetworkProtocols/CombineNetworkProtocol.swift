import Combine
import Foundation

@available(iOS 13.0, *)
public protocol CombineRequestProtocol {
    func request(
        for request: NetworkRequestProtocol,
        receive: DispatchQueue
    ) -> AnyPublisher<Data, NetworkError>

    func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        receive: DispatchQueue
    ) -> AnyPublisher<T, NetworkError> where T: Decodable

    func serialRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) -> AnyPublisher<Data?, NetworkError>
    
    func concurrentRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) -> AnyPublisher<[Data?], NetworkError>
}

@available(iOS 13.0, *)
public protocol CombineUploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkUploadResponse, NetworkError>

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkUploadResponse, NetworkError>
    
//    func serialUpload(
//         with requests: [NetworkUploadRequestProtocol],
//         receive: DispatchQueue
//     ) -> AnyPublisher<NetworkUploadResponse, NetworkError>

    func concurrentUpload(
        with requests: [NetworkUploadRequestProtocol],
        receive: DispatchQueue
    ) -> AnyPublisher<[NetworkUploadResponse], NetworkError>
}

@available(iOS 13.0, *)
public protocol CombineDownloadProtocol {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkDownloadResponse, NetworkError>
}

@available(iOS 13.0, *)
public protocol CombineNetworkSessionTaskProtocol {
    func suspend(for request: URLRequest)
    func resume(for request: URLRequest)
    func cancel(for request: URLRequest)
    func cancelAllRequests()
    func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void)
}

@available(iOS 13.0, *)
public protocol CombineWebSocketProtocol {
    func start(for request: NetworkRequestProtocol) -> AnyPublisher<Bool, Error>
    func send(message: NetworkSocketMessage) -> AnyPublisher<Bool, Error>
    func receive() -> AnyPublisher<NetworkSocketMessage, Error>
    func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: String?
    ) -> AnyPublisher<Bool, Error>
}

// MARK: Conforming Request, Upload, Download, URLSessionTask, WebSocket to NetworkProtocol as this has been exposed to host app.
@available(iOS 13.0, *)
public protocol CombineNetworkProtocol:
    CombineRequestProtocol,
    CombineUploadProtocol,
    CombineDownloadProtocol,
    CombineNetworkSessionTaskProtocol,
    CombineWebSocketProtocol
{}
