import Foundation

private struct JWTErrorBody: Decodable {
    let message: String?
    let statusCode: Int?
}

public struct NetworkError: Error, Codable, Equatable {
    public let title: NetworkErrorTitle
    public let code: NetworkErrorCode
    public let errorMessage: NetworkErrorMessage
    public let userMessage: String
    public var response: URLResponse? = nil
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        return lhs.title == rhs.title &&
        lhs.code == rhs.code &&
        lhs.errorMessage == rhs.errorMessage &&
        lhs.userMessage == rhs.userMessage
    }
    
    enum CodingKeys: String, CodingKey {
        case title, code, errorMessage, userMessage
    }
}

private struct HTTPError: Codable {
    let title: String
    let code: Int
    let errorMessage: String
    let userMessage: String
}

    //MARK: public errors for network
public extension NetworkError {
    static let noInternet =
    NetworkError(
        title: .noInternetTitle,
        code: .noInternet,
        errorMessage: .noInternet,
        userMessage: .empty
    )
    
    static let refreshTokenExpired = NetworkError(
        title: .unauthorizedTitle,
        code: .unauthorized,
        errorMessage: .refreshTokenExpired,
        userMessage: "Your session has expired. Please log in again."
    )
    
    static let tokenRevoked = NetworkError(
        title: .forbiddenTitle,
        code: .forbidden,
        errorMessage: .tokenRevoked,
        userMessage: "Your session is no longer valid. Please sign in again."
    )
    
    static let requestInterceptionFailed =
    NetworkError(
        title: .requestInterceptionFailed,
        code: .requestInterceptionFailed,
        errorMessage: .requestInterceptionFailed,
        userMessage: .empty
    )
    
    static let retryInterceptionFailed =
    NetworkError(
        title: .retryInterceptionFailed,
        code: .retryInterceptionFailed,
        errorMessage: .retryInterceptionFailed,
        userMessage: .empty
    )
    
    static let badUrl =
    NetworkError(
        title: .badUrlTitle,
        code: .badUrl,
        errorMessage: .badUrl,
        userMessage: .empty
    )
    
    static let missingApiConfiguration =
    NetworkError(
        title: .apiConfig,
        code: .apiConfig,
        errorMessage: .apiConfig,
        userMessage: .empty
    )
    
    static let socketStreamsFailure =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Failed to create streams."),
        userMessage: "Failed to create streams."
    )
    
    static let socketStreamsOutputFailure =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Output stream is nil."),
        userMessage: "Output stream is nil."
    )
    
    static let socketStreamsInputFailure =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Input stream is nil."),
        userMessage: "Input stream is nil."
    )
    
    static let socketSendMessageFailure =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Failed to send message."),
        userMessage: "Failed to send message."
    )
    
    static let socketDataReadingFailure =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Failed to read data."),
        userMessage: "Failed to read data."
    )
    
    static let socketStreamsClosed =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Socket streams closed"),
        userMessage: "Failed to fetch streams from server."
    )
    
    static let socketConnectionFailure =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Socket connection is nil"),
        userMessage: "Unable to connect to socket, please check the connection"
    )
    
    static let socketDisconnected =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Socket not connected"),
        userMessage: "Socket not connected"
    )
    
    static let invalidHost = NetworkError(
        title: .socket,
        code: .invalidHost,
        errorMessage: .some("The provided host is invalid."),
        userMessage: "Please check the host and try again."
    )
    
    static let dataToCodableCobversionFailed = NetworkError(
        title: .dataToCodableConversion,
        code: .dataToCodableConversion,
        errorMessage: .codableConversion,
        userMessage: "Codable conversion failed while converting data to codable model"
    )
    
    static let invalidPort = NetworkError(
        title: .socket,
        code: .invalidPort,
        errorMessage: .some("The provided port is invalid."),
        userMessage: "Please check the port number and try again."
    )
    
    static let unableToCloseSocket =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("Some problem while closing the socket"),
        userMessage: "Socket not cancelled"
    )
    
    static let socketClosureTimeout =
    NetworkError(
        title: .socket,
        code: .socket,
        errorMessage: .some("An error occurred while attempting to close the socket."),
        userMessage: "Unable to cancel the socket connection."
    )
    
    static let unknown =
    NetworkError(
        title: .httpResponse,
        code: .unknown,
        errorMessage: .unknown,
        userMessage: NetworkErrorMessage.unknown.value
    )
    
    static let retryNeeded =
    NetworkError(
        title: .retryNeededTitle,
        code: .retryNeeded,
        errorMessage: .retryNeeded,
        userMessage: "A retry is required due to a transient error."
    )
    
    static let timeOut =
    NetworkError(
        title: .timeOut,
        code: .timeOut,
        errorMessage: .timeOut,
        userMessage: "The server timed out waiting for your request. Please try again."
    )
    
    static let badRequestConstructed =
    NetworkError(
        title: .badUrlTitle,
        code: .badUrlTitle,
        errorMessage: .badUrlTitle,
        userMessage: "The server timed out waiting for your request. Please try again."
    )
    
    static let uploadCancelled =
    NetworkError(
        title: .upload,
        code: .uploadCode,
        errorMessage: .some("Upload cancelled"),
        userMessage: "Upload cancelled"
    )
    
    static let uploadSuspended =
    NetworkError(
        title: .upload,
        code: .uploadCode,
        errorMessage: .some("Upload Suspended"),
        userMessage: "Upload Suspended"
    )
    
    static let downloadSuspended =
    NetworkError(
        title: .upload,
        code: .uploadCode,
        errorMessage: .some("Download Suspended"),
        userMessage: "Download Suspended"
    )
    
    static let downloadCancelled =
    NetworkError(
        title: .upload,
        code: .uploadCode,
        errorMessage: .some("Download cancelled"),
        userMessage: "Download cancelled"
    )
    
    static let jsonRequestToJsonStringConversionError =
    NetworkError(
        title: .json,
        code: .jsonToJsonStirngConversion,
        errorMessage: .jsonToJsonStirngConversion,
        userMessage: "Failed to convert json to json string"
    )
    
    static let jsonSerializationError =
    NetworkError(
        title: .json,
        code: .jsonSerializationError,
        errorMessage: .jsonSerializationError,
        userMessage: "Failed to serialize json"
    )
    
    static var redirected: (Int) -> NetworkError {
        return { status in
            NetworkError(
                title: .redirected(statusCode: status),
                code: .redirected(statusCode: status),
                errorMessage: .redirected,
                userMessage: .empty
            )
        }
    }
    
    static var saveUrlToFileManager: (String) -> NetworkError {
        return { errorMessage in
            NetworkError(
                title: .fileSavingError,
                code: .fileSavingError,
                errorMessage: .some(errorMessage),
                userMessage: .empty
            )
        }
    }
    
    static var serverError: (Int) -> NetworkError {
        return { status in
            NetworkError(
                title: .serverError(code: status),
                code: .some(status),
                errorMessage: .some("Server responded with status code \(status)."),
                userMessage: "Something went wrong. Please try again later."
            )
        }
    }
    
    static var sslError: (Int) -> NetworkError {
        return { code in
            NetworkError(
                title: .sslError(code: code),
                code: .some(code),
                errorMessage: .some("Secure-connection error (\(code))"),
                userMessage: "We couldn’t establish a secure connection. " +
                "Please check your network or try again later."
            )
        }
    }
    
    static func validateHTTPError(urlResponse: HTTPURLResponse?, responseData: Data?) -> NetworkError? {
        guard let response = urlResponse else {
            return .unknown
        }
        
        switch response.statusCode {
            case 200 ... 299:
                return nil
            case 300 ... 399:
                return .redirected(response.statusCode)
            case 408, 429, 500, 502, 503, 504:
                return .retryNeeded
            case 401:
                return .refreshTokenExpired
            case 403:
                return .tokenRevoked
                
            default:
                do {
                    let errorModel = try makeNetworkErrorModel(codable: HTTPError.self)
                    if let model = errorModel?.first(where: { $0.code == response.statusCode }) {
                        return .init(
                            title: .some(model.title),
                            code: .some(model.code),
                            errorMessage: .some(model.errorMessage),
                            userMessage: model.userMessage,
                            response: response
                        )
                    } else {
                            // Fallback if not mapped in model
                        return .serverError(response.statusCode)
                    }
                } catch {
                        // Log and fallback to decoding error
                    print("⚠️ Failed to decode HTTPError model: \(error)")
                    return .errorInCodableConversion
                }
        }
    }
    
    static func convertErrorToNetworkError(error: NSError) -> NetworkError {
        let errorcode = error.code
        let domain = error.domain
        let userMessage = error.localizedDescription
        var errorMessage: String = .empty
        
        if error.code == NSURLErrorNotConnectedToInternet {
            return .noInternet
        }
        
        if error.code == NSURLErrorTimedOut {
            return .timeOut
        }
        
        if error.domain == NSURLErrorDomain {
            switch error.code {
                case NSURLErrorSecureConnectionFailed,
                    NSURLErrorServerCertificateHasBadDate,
                    NSURLErrorServerCertificateUntrusted,
                    NSURLErrorServerCertificateHasUnknownRoot,
                    NSURLErrorServerCertificateNotYetValid,
                    NSURLErrorClientCertificateRejected,
                NSURLErrorClientCertificateRequired:
                    return .sslError(error.code)
                    
                default:
                    break
            }
        }
        
        errorMessage  = (error.userInfo[NSURLErrorFailingURLErrorKey] as? NSURL)?.absoluteString ?? ""
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

    //MARK: private errors for network
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
        guard let resourceBundle = Bundle.current.url(
            forResource: Copy.fileName,
            withExtension: Copy.fileType
        ) else {
            throw Self.httpErrorNotFound
        }
        
        do {
            let jsonData = try Data(contentsOf: resourceBundle)
            let model = try JSONDecoder().decode([T].self, from: jsonData)
            return model
        } catch {
            throw error
        }
    }
}

private class BundleFinder {}

extension Bundle {
    class var current: Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        return Bundle(for: BundleFinder.self)
#endif
    }
}

