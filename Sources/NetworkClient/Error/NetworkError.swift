import Foundation

public struct NetworkError: Error, Codable {
    public let title: NetworkErrorTitle
    public let code: NetworkErrorCode
    public let errorMessage: NetworkErrorMessage
    public let userMessage: String
}

private struct GlobalError: Codable {
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
                let errorModel = try makeNetworkErrorModel()
                guard let model = errorModel?.first(where: {$0.code == response.statusCode}) else {
                    return .errorInGloabalErrorsConversion
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
        var message: String = .empty
        var path: String = .empty
        
        do {
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch let DecodingError.dataCorrupted(context) {
            throw Self.jsonCodableConversionError(message: context.debugDescription)
        } catch let DecodingError.keyNotFound(key, context) {
            message = "Key '\(key)' not found: \(context.debugDescription)"
            path = "codingPath: \(context.codingPath)"
            throw Self.jsonCodableConversionError(message: "\(message) \n \(path)")
        } catch let DecodingError.valueNotFound(value, context) {
            message = "Value '\(value)' not found: \(context.debugDescription)"
            path = "codingPath: \(context.codingPath)"
            throw Self.jsonCodableConversionError(message: "\(message) \n \(path)")
        } catch let DecodingError.typeMismatch(type, context)  {
            message = "Type '\(type)' mismatch: \(context.debugDescription)"
            path = "codingPath: \(context.codingPath)"
            throw Self.jsonCodableConversionError(message: "\(message) \n \(path)")
        } catch {
            throw Self.jsonCodableConversionError(message: error.localizedDescription)
        }
    }
}

private extension NetworkError {
    enum Copy {
        static let fileName = "NetworkErrors"
        static let fileType = "json"
        static let nsErrorURLKey = "NSErrorFailingURLKey"
        static let globalError = "Failed to convert GlobalError object while response status is not available in NetworkErrors.json"
    }

    static var errorInCodableConversion: NetworkError {
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .codableConversion,
            userMessage: .empty
        )
    }
    
    static var errorInGloabalErrorsConversion: NetworkError {
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .some(Copy.globalError),
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
    
    static func makeNetworkErrorModel() throws -> [GlobalError]? {
        guard let ressourceURL = Bundle.module.url(
            forResource: Copy.fileName,
            withExtension: Copy.fileType
        ) else {
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: ressourceURL)
            let model = try JSONDecoder().decode([GlobalError].self,
                                                 from: jsonData)
            return model
        } catch {
            throw error
        }
    }
}
