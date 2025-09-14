import Foundation

public enum NetworkErrorTitle: Codable, Equatable {
    case noInternetTitle
    case badUrlTitle
    case unknown
    case api
    case apiConfig
    case httpResponse
    case retryNeededTitle
    case json
    case download
    case upload
    case apiDelegate
    case socket
    case some(String)
    case requestInterceptionFailed
    case retryInterceptionFailed
    case timeOut
    case dataToCodableConversion
    case redirected(statusCode: Int)
    case sslError(code: Int)
    case serverError(code: Int)
    case unauthorizedTitle
    case forbiddenTitle
    case fileSavingError
}

extension NetworkErrorTitle {
    public var value: String {
        switch self {
            case .noInternetTitle: return "No internet"
            case .badUrlTitle: return "Bad request constructed"
            case .unknown: return "Unknown"
            case .api: return "Api error"
            case .httpResponse: return "HTTResponse error"
            case .json: return "Json or codable error"
            case .download: return "Api download error"
            case .upload: return "Api upload error"
            case .apiDelegate: return "Urlsession delegate error"
            case .socket: return "Websocket error"
            case let .some(title): return title
            case .retryNeededTitle: return "Retry Needed"
            case .requestInterceptionFailed: return "Request interceptor Failed"
            case .retryInterceptionFailed: return "Retry interceptor Failed"
            case .timeOut: return "Request Timeout"
            case .dataToCodableConversion: return "Codable Conversion Failed"
            case .apiConfig: return "Api Configuration"
            case let .redirected(statusCode): return "Redirected with status code: \(statusCode)"
            case let .sslError(code): return "SSL Handshake failed with code: \(code)"
            case let .serverError(code): return "Server returned error with code: \(code)"
            case .unauthorizedTitle: return "Unauthorized"
            case .forbiddenTitle: return "Access Denied"
            case .fileSavingError: return "File Manager Error"
        }
    }
}
