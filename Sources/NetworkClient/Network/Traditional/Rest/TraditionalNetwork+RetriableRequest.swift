
struct RetriableRequest: NetworkRequestProtocol, NetworkDownloadRequestProtocol {
    var saveDownloadedUrlToLocation: URL?
    var timeoutInterval: TimeInterval { base.timeoutInterval }
    var httpMethod: NetworkRequestMethod { base.httpMethod }
    var urlComponents: URLComponents? { base.urlComponents }
    var httpHeaderFields: NetworkHTTPHeaderField? { base.httpHeaderFields }
    var shouldRetryDuringNoInternet: Bool { base.shouldRetryDuringNoInternet }
    var httpBodyParameters: NetworkBodyRequestParameters? { base.httpBodyParameters }
    var bodyType: BodyType { base.bodyType }
    var cachePolicy: NetworkCachePolicy? { base.cachePolicy }
    var allowedRequestInterceptorIDs: Set<InterceptorID>? { base.allowedRequestInterceptorIDs }
    var allowedRetryInterceptorIDs: Set<InterceptorID>? { base.allowedRetryInterceptorIDs }
    private let base: NetworkRequestProtocol
    private let increment: Bool
    
    init(base: NetworkRequestProtocol, increment: Bool = true) {
        self.base = base
        self.increment = increment
    }
    
    func makeRequest() throws -> URLRequest {
        var req = try base.makeRequest()
        if increment {
            req.retryCount += 1
        }
        return req
    }
}

