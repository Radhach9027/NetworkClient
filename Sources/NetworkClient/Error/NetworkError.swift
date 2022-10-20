import Foundation

public struct NetworkError: Error, Codable {
    public let title: NetworkErrorTitle
    public let code: NetworkErrorCode
    public let errorMessage: NetworkErrorMessage
    public let userMessage: String
}

extension NetworkError {
    public static var noInternet: NetworkError {
        NetworkError(
            title: .noInternetTitle,
            code: .noInternet,
            errorMessage: .noInternet,
            userMessage: .empty
        )
    }

    public static var badUrl: NetworkError {
        NetworkError(
            title: .badUrlTitle,
            code: .badUrl,
            errorMessage: .badUrl,
            userMessage: .empty
        )
    }

    public static var unknown: NetworkError {
        NetworkError(
            title: .httpResponse,
            code: .unknown,
            errorMessage: .unknown,
            userMessage: NetworkErrorMessage.unknown.message
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
            title: .some(domain),
            code: .some(errorcode),
            errorMessage: .some(errorMessage),
            userMessage: userMessage
        )
    }
    
    public static func test() {
        do {
            let errorModel = try makeNetworkErrorModel()
            debugPrint(errorModel)
        } catch {
            debugPrint("Failed")
        }
    }
}

private extension NetworkError {
    enum Copy {
        static let fileName = "NetworkErrors"
        static let fileType = "json"
        static let nsErrorURLKey = "NSErrorFailingURLKey"
    }

    static var errorInCodableConversion: NetworkError {
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .codableConversion,
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
