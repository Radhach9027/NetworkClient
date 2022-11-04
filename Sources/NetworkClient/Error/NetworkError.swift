import Foundation

public struct NetworkError: Error, Codable {
    public let title: NetworkErrorTitle
    public let code: NetworkErrorCode
    public let errorMessage: NetworkErrorMessage
    public let userMessage: String
}

private struct HTTPError: Codable {
    let title: String
    let code: Int
    let errorMessage: String
    let userMessage: String
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
            userMessage: NetworkErrorMessage.unknown.value
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
                let errorModel = try makeNetworkErrorModel(codable: HTTPError.self)
                guard let model = errorModel?.first(where: {$0.code == response.statusCode}) else {
                    return .errorInHTTPErrorsConversion
                }
                return .init(
                    title: .some(model.title),
                    code: .some(model.code),
                    errorMessage: .some(model.errorMessage),
                    userMessage: model.userMessage
                )
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
    
    static func dataDecoding<T>(codable: T.Type, data: Data) throws -> T where T: Decodable {
        let decoder = JSONDecoder()
        do {
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch let DecodingError.dataCorrupted(context) {
            throw Self.jsonCodableConversionError(message: context.debugDescription)
        } catch let DecodingError.keyNotFound(key, _) {
            throw Self.jsonCodableConversionError(message: "No value associated with key = '\(key.stringValue)' in '\(T.self)' model")
        } catch let DecodingError.valueNotFound(value, context) {
            throw Self.jsonCodableConversionError(message: "'\(value)' not found: \(context.debugDescription) in '\(T.self)' model")
        } catch let DecodingError.typeMismatch(type, context)  {
            throw Self.jsonCodableConversionError(message: "'\(type)' mismatch: \(context.debugDescription) in '\(T.self)' model")
        } catch {
            throw Self.jsonCodableConversionError(message: error.localizedDescription)
        }
    }
}

private extension NetworkError {
    enum Copy {
        static let fileName = "HTTPErrors"
        static let fileType = "json"
        static let nsErrorURLKey = "NSErrorFailingURLKey"
        static let HTTPError = "Failed to convert HTTPErrors object while response status is not available in HTTPErrors.json"
        static let HTTPErrorNotFound = "Failed to load HTTPErrors.json file from resource folder"
    }

    static var errorInCodableConversion: NetworkError {
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .codableConversion,
            userMessage: .empty
        )
    }
    
    static var errorInHTTPErrorsConversion: NetworkError {
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .some(Copy.HTTPError),
            userMessage: .empty
        )
    }
    
    static var httpErrorNotFound: NetworkError {
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .some(Copy.HTTPErrorNotFound),
            userMessage: .empty
        )
    }

    static func jsonCodableConversionError(message: String) -> NetworkError {
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .some(message),
            userMessage: .empty
        )
    }
    
    static func makeNetworkErrorModel<T>(codable: T.Type) throws -> [T]? where T: Decodable {
        guard let ressourceURL = Bundle.module.url(
            forResource: Copy.fileName,
            withExtension: Copy.fileType
        ) else {
            throw Self.httpErrorNotFound
        }

        do {
            let jsonData = try Data(contentsOf: ressourceURL)
            let model = try JSONDecoder().decode([T].self,
                                                 from: jsonData)
            return model
        } catch {
            throw error
        }
    }
}
