import Foundation

public enum NetworkErrorMessage: Codable, Equatable {
    case noInternet
    case badUrl
    case unknown
    case codableConversion
    case some(String)
    case retryNeeded
    case requestInterceptionFailed
    case retryInterceptionFailed
    case timeOut
    case badUrlTitle
    case apiConfig
    case jsonToJsonStirngConversion
    case jsonSerializationError
    case redirected
    case sslError
    case refreshTokenExpired
    case tokenRevoked
}

extension NetworkErrorMessage {
    public var value: String {
        switch self {
        case .noInternet: return "Something wrong with the url that has been constructed, Please check and try again"
        case .badUrl: return "Something wrong with the url that has been constructed, Please check and try again"
        case .badUrlTitle: return "The request you've prepared was not right, please check your endpoint once again"
        case .unknown: return "An unknown error occurred while processing request, please check and try again."
        case .codableConversion: return "Issue in converting NetworkErrors.json via codable model."
        case let .some(title): return title
        case .retryNeeded: return "A transient error occurred. It’s advisable to retry after a brief wait, or if your network connection has stabilized."
        case .requestInterceptionFailed:
            return "There is a request adapter in the network, but you haven't confirmed the Retry protocol in your source."
        case .retryInterceptionFailed:
            return "A retry was triggered from the network, but you haven't confirmed the Retry protocol in your source."
        case .timeOut: return "The server timed out waiting for your request. Please try again."
        case .apiConfig: return "Some of the attributes in the api configuration were missing, please check your DI and try again"
        case .jsonToJsonStirngConversion: return "Issue in converting JSON Request Body to Json String"
        case .jsonSerializationError: return "Issue in serializing JSON Request Body"
        case .redirected:
             return "The request was redirected unexpectedly. Please verify the target endpoint or redirection rules."
         case .sslError:
             return "The connection couldn’t be secured due to an SSL error. Please check your certificate and internet security settings."
        case .refreshTokenExpired: return "Refresh token is expired or invalid."
        case .tokenRevoked: return"The token has been revoked and can no longer be used."
        }
    }
}
