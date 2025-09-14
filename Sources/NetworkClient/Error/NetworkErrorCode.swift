import Foundation

public enum NetworkErrorCode: Codable, Equatable {
    case unknown
    case noInternet // No internet connection
    case badUrl // URL construction failed
    case jsonFileError // Error in JSON conversion or reading
    case api // Error from API
    case apiConfig // Error from API Configuration
    case downloadCode // Download Error Code
    case uploadCode // Upload Error Code
    case socket // socket error code
    case webSocket // webSocket error code
    case invalidHost // Invalid host error
    case invalidPort // Invalid port error
    case some(Int) // Send custom code if needed
    case retryNeeded
    case requestInterceptionFailed
    case retryInterceptionFailed
    case timeOut
    case badUrlTitle
    case dataToCodableConversion
    case jsonToJsonStirngConversion
    case jsonSerializationError
    case redirected(statusCode: Int)
    case sslError(code: Int)
    case unauthorized
    case forbidden
    case fileSavingError
}

extension NetworkErrorCode {
    public var value: Int {
        switch self {
        case .unknown:                       return 0
        case .noInternet:                    return -1
        case .badUrl:                        return -2
        case .jsonFileError:                 return -3
        case .dataToCodableConversion:       return -4
        case .jsonToJsonStirngConversion:    return -5
        case .jsonSerializationError:        return -6
        case .badUrlTitle:                   return -7
        case .fileSavingError:               return -8
        case .api:                           return -111
        case .apiConfig:                     return -110
        case .downloadCode:                  return -222
        case .uploadCode:                    return -333
        case .unauthorized:                  return 401
        case .forbidden:                     return 403
        case .socket:                        return -444
        case .webSocket:                     return -443
        case .invalidHost:                   return -445
        case .invalidPort:                   return -446
        case .retryNeeded:                   return 1002
        case .requestInterceptionFailed:     return -555
        case .retryInterceptionFailed:       return -556
        case .timeOut:                       return -666
        case let .redirected(statusCode):    return statusCode // 300…399
        case let .sslError(code):            return code // –1200…–1216
        case let .some(code):                return code
        }
    }
}
