import Foundation

public protocol NetworkRequestProtocol {
    var timeoutInterval: TimeInterval { get }
    var httpMethod: NetworkRequestMethod { get }
    var urlComponents: URLComponents? { get }
    var httpHeaderFields: NetworkHTTPHeaderField? { get }
    var shouldRetryDuringNoInternet: Bool { get }
    var httpBodyParameters: NetworkBodyRequestParameters? { get }
    var bodyType: BodyType { get }
    func makeRequest() throws -> URLRequest
    var cachePolicy: NetworkCachePolicy? { get }
    var allowedRequestInterceptorIDs: Set<InterceptorID>? { get }
    var allowedRetryInterceptorIDs: Set<InterceptorID>? { get }
}

public extension NetworkRequestProtocol {
    var cachePolicy: NetworkCachePolicy? {
        nil
    }

    var httpHeaderFields: NetworkHTTPHeaderField? {
        nil
    }

    var httpBodyParameters: NetworkBodyRequestParameters? {
        nil
    }

    var timeoutInterval: TimeInterval {
        3
    }

    var shouldRetryDuringNoInternet: Bool {
        false
    }
    
    var allowedRequestInterceptorIDs: Set<InterceptorID>? {
        nil
    }
    
    var allowedRetryInterceptorIDs: Set<InterceptorID>? {
        nil
    }
    
    var bodyType: BodyType {
        .json
    }

    func makeRequest() throws -> URLRequest {
        guard let url = urlComponents?.url,
              url.isValid else {
            throw NetworkError.badUrl
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval
        request.httpMethod = httpMethod.rawValue
        httpHeaderFields?.headers.forEach {
            request.setValue(
                $0.value.description,
                forHTTPHeaderField: $0.key.description
            )
        }

        do {
            let body = try makeBody()
            request.httpBody = body
        } catch {
            throw error
        }
        return request
    }
}

private extension NetworkRequestProtocol {
    func makeBody() throws -> Data? {
        guard let parameters = httpBodyParameters else {
            return nil
        }
        
        switch bodyType {
        case .json:
            return try makeJSONBody(from: parameters)
        case .queryString:
            return try makeJsonBodyAsString(from: parameters)
        }
    }
    
    func makeJSONBody(from parameters: NetworkBodyRequestParameters) throws -> Data {
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: parameters,
                options: []
            )
            return jsonData
        } catch {
            throw NetworkError.jsonSerializationError
        }
    }
    
    func makeJsonBodyAsString(from parameters: NetworkBodyRequestParameters) throws -> Data {
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: parameters,
                options: []
            )
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let singleLineJsonString = jsonString.replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return singleLineJsonString.data(using: .utf8) ?? Data()
            }
            throw NetworkError.jsonRequestToJsonStringConversionError
        } catch {
            throw NetworkError.jsonRequestToJsonStringConversionError
        }
    }
}
