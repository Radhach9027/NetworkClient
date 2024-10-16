import Foundation

public enum NetworkErrorMessage: Codable {
    case noInternet
    case badUrl
    case unknown
    case codableConversion
    case some(String)
    case retryNeeded
}

extension NetworkErrorMessage {
    public var value: String {
        switch self {
            case .noInternet: return "Something wrong with the url that has been constructed, Please check and try again"
            case .badUrl: return "Something wrong with the url that has been constructed, Please check and try again"
            case .unknown: return "An unknown error occurred while processing request, please check and try again."
            case .codableConversion: return "Issue in converting NetworkErrors.json via codable model."
            case .some(let title): return title
            case .retryNeeded: return "A transient error occurred. It’s advisable to retry after a brief wait, or if your network connection has stabilized."

        }
    }
}
