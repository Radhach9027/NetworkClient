import Foundation

public enum NetworkCodes: Codable {
    case unknown
    case noInternet // No internet connection
    case badUrl // Url construction failed
    case jsonFileError // Error in json conversion or reading
    case api // Error from api
    case downloadCode // Download Error Code
    case uploadCode // Download Error Code
    case some(Int) // Send custom code if needed
}

extension NetworkCodes {
    var value: Int {
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

public struct NetworkError: Error, Codable {
    public let title: String
    public let code: NetworkCodes
    public let errorMessage: String
    public let userMessage: String
}

extension NetworkError {
    public static var noInternet: NetworkError {
        NetworkError(
            title: Copy.noInternetTitle,
            code: NetworkCodes.noInternet,
            errorMessage: Copy.noInternet,
            userMessage: .empty
        )
    }

    public static var badUrl: NetworkError {
        NetworkError(
            title: Copy.badUrlTitle,
            code: NetworkCodes.badUrl,
            errorMessage: Copy.badUrl,
            userMessage: .empty
        )
    }

    public static var unknown: NetworkError {
        NetworkError(
            title: Copy.HTTPresponseNil,
            code: NetworkCodes.unknown,
            errorMessage: .empty,
            userMessage: Copy.unknown
        )
    }

    static func validateHTTPError(urlResponse: HTTPURLResponse?) -> NetworkError? {
        guard let response = urlResponse else {
            return unknown
        }

        switch response.statusCode {
        case 200 ... 299:
            return nil
        default:
            do {
                let errorModel = try makeNetworkErrorModel()
                return errorModel?.first(where: { $0.code.value == response.statusCode })
            } catch {
                return .errorInCodableConversion
            }
        }
    }

    static func convertErrorToNetworkError(error: NSError) -> NetworkError {
        let errorcode = error.code
        let domain = error.domain
        let userMessage = error.localizedDescription
        var errorMessage: String = .empty

        if let urlError = error.userInfo.first(where: { $0.key == Copy.nsErrorURLKey })?.value {
            errorMessage = String(describing: urlError)
        }

        return NetworkError(
            title: domain,
            code: .some(errorcode),
            errorMessage: errorMessage,
            userMessage: userMessage
        )
    }
}

private extension NetworkError {
    enum Copy {
        static let fileName = "NetworkErrors"
        static let fileType = "json"
        static let noInternet = "Something wrong with the url that has been constructed, Please check and try again"
        static let noInternetTitle = "No Internet"
        static let badUrlTitle = "Bar Request Constructed"
        static let badUrl = "Something wrong with the url that has been constructed, Please check and try again"
        static let unknown = "An unknown error occurred while processing request, please check and try again."
        static let HTTPresponseNil = "HTTPURLResponse is nil"
        static let apiError = "ApiError"
        static let nsErrorURLKey = "NSErrorFailingURLKey"
        static let codableConversionError = "NetworErrors Json File"
        static let codableConversionErrorMessage = "Issue in converting NetworkErrors.json via codable model."
    }

    static var errorInCodableConversion: NetworkError {
        NetworkError(
            title: Copy.codableConversionError,
            code: NetworkCodes.jsonFileError,
            errorMessage: Copy.codableConversionErrorMessage,
            userMessage: .empty
        )
    }

    static func makeNetworkErrorModel() throws -> [NetworkError]? {
        guard let ressourceURL = Bundle.main.url(forResource: Copy.fileName,
                                                 withExtension: Copy.fileType) else {
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: ressourceURL)
            let model = try JSONDecoder().decode([NetworkError].self,
                                                 from: jsonData)
            return model
        } catch {
            throw error
        }
    }
}
