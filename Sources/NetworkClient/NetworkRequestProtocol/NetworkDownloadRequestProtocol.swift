import Foundation

public protocol NetworkDownloadRequestProtocol: NetworkRequestProtocol {
    var saveDownloadedUrlToLocation: URL? { get }
}

public extension NetworkDownloadRequestProtocol {
    var saveDownloadedUrlToLocation: URL? {
        nil
    }
}
