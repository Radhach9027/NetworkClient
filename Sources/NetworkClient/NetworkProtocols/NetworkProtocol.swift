import Combine
import Foundation

public protocol RequestProtocol {
    func request(
        for request: NetworkRequestProtocol,
        receive: DispatchQueue
    ) -> AnyPublisher<Data, NetworkError>
}

public protocol UploadProtocol {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<UploadNetworkResponse, NetworkError>
    
    func uploadMultipart(
        for request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> AnyPublisher<Data, NetworkError>
}

public protocol DownloadProtocol {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<DownloadNetworkResponse, NetworkError>
}

public protocol SessionCancelProtocol {
    func cancelAllTasks()

    func cancelTaskWithUrl(url: URL)

    static var isInternetReachable: Bool { get }
}

public protocol NetworkProtocol: RequestProtocol, UploadProtocol, DownloadProtocol, SessionCancelProtocol {}
