import Foundation
import os

public enum LoggerCategory {
    case requests, errors
}

public enum LoggerPrivacy {
    case open, encapsulate, encrypt
}

extension LoggerCategory {
    public var description: String {
        switch self {
        case .requests:
            return "NetworkRequests"
        case .errors:
            return "NetworkErrors"
        }
    }
}

public protocol NetworkLoggerProtocol {
    func logRequest(url: URL,
                    error: NetworkError,
                    type: OSLogType,
                    privacy: LoggerPrivacy)
}

public struct NetworkLogger: NetworkLoggerProtocol {
    private var identifier: String
    private var category: LoggerCategory
    private let logger: Logger

    public init(identifier: String,
                category: LoggerCategory) {
        self.identifier = identifier
        self.category = category
        logger = Logger(
            subsystem: identifier,
            category: category.description
        )
    }

    public func logRequest(
        url: URL,
        error: NetworkError,
        type: OSLogType,
        privacy: LoggerPrivacy
    ) {
        let errorString = """
        Error = \(error.title),
        ErrorCode = \(error.code),
        ErrorMessage = \(error.errorMessage),
        URL = \(url)
        """

        switch privacy {
        case .open:
            logger.log(level: type, "NetworkError: \(errorString, privacy: .public)")
        case .encapsulate:
            logger.log(level: type, "NetworkError: \(errorString, privacy: .private)")
        case .encrypt:
            logger.log(level: type, "NetworkError: \(errorString, privacy: .private(mask: .hash))")
        }
    }
}
