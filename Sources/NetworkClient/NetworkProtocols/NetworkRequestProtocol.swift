import Foundation

public protocol NetworkRequestProtocol: NetworkEnvironmentProtocol, NetworkCacheProtocol {
    var urlPath: String { get }
    var httpMethod: NetworkRequestMethod { get }
    var urlComponents: URLComponents? { get }
    var httpHeaderFields: NetworkHTTPHeaderField? { get }
    var httpBodyParameters: NetworkBodyRequestParameters? { get }
    var isNetworkReachable: Bool { get }
    var saveDownloadedUrlToLocation: URL? { get }
    var uploadFromFile: URL? { get }
    var uploadFormData: Data? { get }
    func makeRequest() throws -> URLRequest
}

public extension NetworkRequestProtocol {
    var uploadFromFile: URL? {
        nil
    }
    
    var uploadFormData: Data? {
        nil
    }
    
    var saveDownloadedUrlToLocation: URL? {
        nil
    }

    var httpHeaderFields: NetworkHTTPHeaderField? {
        nil
    }

    var httpBodyParameters: NetworkBodyRequestParameters? {
        nil
    }

    var apiKey: String? {
        nil
    }

    var isNetworkReachable: Bool {
        Network.isInternetReachable
    }

    func makeRequest() throws -> URLRequest {
        guard let url = urlComponents?.url,
              url.isValid else {
            throw NetworkError.badUrl
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue

        httpHeaderFields?.headers.forEach {
            request.setValue($0.value.description,
                             forHTTPHeaderField: $0.key.description)
        }

        do {
            let body = try makeBody()
            request.httpBody = body
        } catch {
            throw error
        }

        clearCacheForRequest(request: request)
        guard let isReachableError = manageInternetConnectivityBasedOnCache(request: request) else {
            return request
        }

        throw isReachableError
    }

    func manageInternetConnectivityBasedOnCache(request: URLRequest) -> NetworkError? {
        guard isNetworkReachable else {
            return .noInternet
        }

        return nil
    }
}

private extension NetworkRequestProtocol {
    func makeBody() throws -> Data? {
        guard let parameters = httpBodyParameters else {
            return nil
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters,
                                                      options: .prettyPrinted)
            return jsonData
        } catch {
            throw error
        }
    }

    func clearCacheForRequest(request: URLRequest) {
        if clearCache {
            URLCache.shared.removeCachedResponse(for: request)
        }
    }
}
