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
    ) -> AnyPublisher<T, NetworkError> where T: Decodable
    
    func serialRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) -> PassthroughSubject<Data?, NetworkError>
}

public protocol AsyncUploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkUploadResponse, NetworkError>
    
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
}

public protocol AsyncNetworkProtocol: AsyncRequestProtocol, AsyncUploadProtocol, AsyncDownloadProtocol {}
