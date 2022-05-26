import Foundation
import Combine

public protocol RequestProtocol {
    
    func request(for request: URLRequest,
                 receive: DispatchQueue) -> AnyPublisher<Data, NetworkError>
    
    func request(for url: URL,
                 receive: DispatchQueue) -> AnyPublisher<Data, NetworkError>
}

public protocol UploadProtocol {
    
    func upload(with request: URLRequest,
                from bodyData: Data?,
                receive: DispatchQueue) -> AnyPublisher<UploadNetworkResponse, NetworkError>
    
    func upload(for request: URLRequest,
                fileURL: URL,
                receive: DispatchQueue) -> AnyPublisher<UploadNetworkResponse, NetworkError>
    
}

public protocol DownloadProtocol {
    
    func download(for request: URLRequest,
                  receive: DispatchQueue) -> AnyPublisher<DownloadNetworkResponse, NetworkError>
    
    func download(for url: URL,
                  receive: DispatchQueue) -> AnyPublisher<DownloadNetworkResponse, NetworkError>
    
}

public protocol sessionCancelProtocol {
    
    func cancelAllTasks()
    
    func cancelTaskWithUrl(url: URL)
    
    static var isInternetReachable: Bool { get }
}

public protocol NetworkProtocol : RequestProtocol, sessionCancelProtocol {}
