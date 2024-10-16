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
    public static let noInternet =
        NetworkError(
            title: .noInternetTitle,
            code: .noInternet,
            errorMessage: .noInternet,
            userMessage: .empty
        )

    public static let badUrl =
        NetworkError(
            title: .badUrlTitle,
            code: .badUrl,
            errorMessage: .badUrl,
            userMessage: .empty
        )
    
    public static let socketDisconnected =
        NetworkError(
            title: .socket,
            code: .socket,
            errorMessage: .some("Socket not connected"),
            userMessage: "Socket not connected"
        )
    
    public static let unableToCloseSocket =
        NetworkError(
            title: .socket,
            code: .socket,
            errorMessage: .some("Some problem while closing the socket"),
            userMessage: "Socket not cancelled"
        )
    
    public static let socketClosureTimeout =
        NetworkError(
            title: .socket,
            code: .socket,
            errorMessage: .some("An error occurred while attempting to close the socket."),
            userMessage: "Unable to cancel the socket connection."
        )

    public static let unknown =
        NetworkError(
            title: .httpResponse,
            code: .unknown,
            errorMessage: .unknown,
            userMessage: NetworkErrorMessage.unknown.value
        )
    
    public static let retryNeeded =
        NetworkError(
            title: .retryNeededTitle,
            code: .retryNeeded,
            errorMessage: .retryNeeded,
            userMessage: "A retry is required due to a transient error."
        )
    

    static func validateHTTPError(urlResponse: HTTPURLResponse?) -> NetworkError? {
        guard let response = urlResponse else {
            return unknown
        }

        switch response.statusCode {
        case 200 ... 299:
            return nil
        case 429: // Too Many Requests
            return retryNeeded // You might want to return retryNeeded for certain status codes
        default:
            do {
                let errorModel = try makeNetworkErrorModel(codable: HTTPError.self)
                guard let model = errorModel?.first(where: { $0.code == response.statusCode }) else {
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
    
    static func dataDecoding<T>(
        codable: T.Type,
        data: Data
    ) throws -> T where T: Decodable {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            switch error {
            case let .dataCorrupted(context):
                throw jsonCodableConversionError(context.debugDescription)
            case let .keyNotFound(key, _):
                throw jsonCodableConversionError("No value associated with key = '\(key.stringValue)' in '\(T.self)' model")
            case let .valueNotFound(value, context):
                throw jsonCodableConversionError("'\(value)' not found: \(context.debugDescription) in '\(T.self)' model")
            case let .typeMismatch(type, context):
                throw jsonCodableConversionError("'\(type)' mismatch: \(context.debugDescription) in '\(T.self)' model")
            @unknown default:
                throw jsonCodableConversionError(error.localizedDescription)
            }
        } catch {
            throw jsonCodableConversionError(error.localizedDescription)
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

    static let errorInCodableConversion =
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .codableConversion,
            userMessage: .empty
        )
    
    static let errorInHTTPErrorsConversion =
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .some(Copy.HTTPError),
            userMessage: .empty
        )
    
    static let httpErrorNotFound =
        NetworkError(
            title: .json,
            code: .jsonFileError,
            errorMessage: .some(Copy.HTTPErrorNotFound),
            userMessage: .empty
        )

    static var jsonCodableConversionError: (String) -> NetworkError {
        return { message in
            NetworkError(
                title: .json,
                code: .jsonFileError,
                errorMessage: .some(message),
                userMessage: .empty
            )
        }
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
