import Foundation

public enum NetworkErrorCode: Codable {
    case unknown
    case noInternet // No internet connection
    case badUrl // Url construction failed
    case jsonFileError // Error in json conversion or reading
    case api // Error from api
    case downloadCode // Download Error Code
    case uploadCode // Download Error Code
    case some(Int) // Send custom code if needed
}

extension NetworkErrorCode {
    public var value: Int {
        switch self {
            case .unknown: return 0
            case .noInternet: return -1
            case .badUrl: return -2
            case .jsonFileError: return -3
            case .api: return -111
            case .downloadCode: return -222
            case .uploadCode: return -333
            case let .some(code): return code
        }
    }
}
