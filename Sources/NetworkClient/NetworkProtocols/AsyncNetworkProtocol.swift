import Combine
import Foundation

public protocol AsyncRequestProtocol {
    func request(
        request: NetworkRequestProtocol,
        receive: DispatchQueue
    ) async throws -> AnyPublisher<Data, NetworkError>
    
    func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        receive: DispatchQueue
    ) async throws -> AnyPublisher<T, NetworkError> where T: Decodable
    
    func serialRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) async throws -> [AnyPublisher<Data?, NetworkError>]
    
    func serialRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        receive: DispatchQueue
    ) async throws -> [AnyPublisher<T, NetworkError>] where T: Decodable
    
    func concurrentRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) async throws -> AnyPublisher<[Data?], NetworkError>
    
    func concurrentRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        receive: DispatchQueue
    ) async throws -> AnyPublisher<[T], NetworkError> where T: Decodable
}

public protocol AsyncUploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkUploadResponse, NetworkError>
    
    func uploadSerial(
        with requests: [NetworkUploadRequestProtocol],
        receive: DispatchQueue
    ) async throws -> [PassthroughSubject<NetworkUploadResponse, NetworkError>]
    
    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkUploadResponse, NetworkError>
}

public protocol AsyncDownloadProtocol {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkDownloadResponse, NetworkError>
    
    func downloadConcurrent(
        for requests: [NetworkDownloadRequestProtocol],
        receive: DispatchQueue
    ) async throws -> [PassthroughSubject<NetworkDownloadResponse, NetworkError>]
    
    func downloadBatch(
        for requests: [NetworkDownloadRequestProtocol],
        receive: DispatchQueue
    ) async throws -> [PassthroughSubject<NetworkDownloadResponse, NetworkError>]
}


public protocol AysncWebSocketProtocol {
    func start(for request: NetworkRequestProtocol) async throws -> Bool
    func send(message: NetworkSocketMessage) async throws -> Bool
    func receive() async throws -> NetworkSocketMessage
    func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: String?
    ) async throws -> Bool
}

public protocol AsyncNetworkProtocol: 
    AsyncRequestProtocol,
    AsyncUploadProtocol,
    AsyncDownloadProtocol,
    AysncWebSocketProtocol {}
