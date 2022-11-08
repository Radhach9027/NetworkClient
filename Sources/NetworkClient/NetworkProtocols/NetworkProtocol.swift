import Combine
import Foundation

public protocol RequestProtocol {
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
    ) -> PassthroughSubject<Data?, NetworkError>
}

public protocol UploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkUploadResponse, NetworkError>

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkUploadResponse, NetworkError>
}

public protocol DownloadProtocol {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkDownloadResponse, NetworkError>
}

public protocol NetworkSessionTaskProtocol {
    func suspend(for request: URLRequest)
    func resume(for request: URLRequest)
    func cancel(for request: URLRequest)
    func cancelAllRequests()
    func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void)
}

public protocol NetworkWebSocketProtocol {
    func start(for url: NetworkRequestProtocol, completion: @escaping (NetworkError?) -> Void)
    func send(message: NetworkSocketMessage, completion: @escaping (NetworkError?) -> Void)
    func receive() -> PassthroughSubject<NetworkSocketMessage, NetworkError>
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: String?)
}

// MARK: Conforming Request, Upload, Download, URLSessionTask, WebSocket to NetworkProtocol as this has been exposed to host app.

public protocol NetworkProtocol:
    RequestProtocol,
    UploadProtocol,
    DownloadProtocol,
    NetworkWebSocketProtocol,
    NetworkSessionTaskProtocol
{}
