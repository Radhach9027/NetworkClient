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
}

public protocol UploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<UploadNetworkResponse, NetworkError>

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<UploadNetworkResponse, NetworkError>
}

public protocol DownloadProtocol {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<DownloadNetworkResponse, NetworkError>
}

public protocol URLSessionTaskProtocol {
    func suspendRequest(request: URLRequest)

    func resumeRequest(request: URLRequest)

    func cancelRequest(request: URLRequest)

    func cancelAllRequests()
    
    func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void)

    static var isInternetReachable: Bool { get }
}

public protocol NetworkProtocol: RequestProtocol, UploadProtocol, DownloadProtocol, URLSessionTaskProtocol {}
