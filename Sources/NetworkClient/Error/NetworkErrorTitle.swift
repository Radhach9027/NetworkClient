import Foundation

public enum NetworkErrorTitle: Codable {
    case noInternetTitle
    case badUrlTitle
    case unknown
    case api
    case httpResponse
    case json
    case download
    case upload
    case apiDelegate
    case socket
    case some(String)
}

extension NetworkErrorTitle {
    public var value: String {
        switch self {
            case .noInternetTitle: return "No internet"
            case .badUrlTitle: return "Bar request constructed"
            case .unknown: return "Unknown"
            case .api: return "Api error"
            case .httpResponse: return "HTTResponse error"
            case .json: return "Json or codable error"
            case .download: return "Api download error"
            case .upload: return "Api upload error"
            case .apiDelegate: return "Urlsession delegate error"
            case .socket: return "Websocket error"
            case .some(let title): return title
        }
    }
}
