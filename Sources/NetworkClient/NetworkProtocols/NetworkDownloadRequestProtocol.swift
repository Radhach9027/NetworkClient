import Foundation

public protocol NetworkDownloadRequestProtocol: NetworkRequestProtocol {
    var saveDownloadedUrlToLocation: URL? { get }
}
