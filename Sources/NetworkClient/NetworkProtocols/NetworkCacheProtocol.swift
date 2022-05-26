import Foundation

public protocol NetworkCacheProtocol {
    var clearCache: Bool { get }
    func manageInternetConnectivityBasedOnCache(request: URLRequest) -> NetworkError?
}

public extension NetworkCacheProtocol {
    
    var clearCache: Bool {
        false
    }
}
