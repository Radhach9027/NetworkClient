import Foundation

public enum NetworkHTTPHeaderField {
    case headerFields(fields: [NetworkHTTPHeaderKeys: NetworkHTTPHeaderValues])

    var headers: [NetworkHTTPHeaderKeys: NetworkHTTPHeaderValues] {
        switch self {
        case let .headerFields(httpHeaders):
            return httpHeaders
        }
    }
}

public enum NetworkHTTPHeaderKeys {
    case authentication
    case contentType
    case acceptType
    case other(value: String)
}

public enum NetworkHTTPHeaderValues {
    case json
    case other(value: String)
}

extension NetworkHTTPHeaderKeys: Hashable {
    var description: String {
        switch self {
        case .authentication:
            return "Authorization"
        case .contentType:
            return "Content-Type"
        case .acceptType:
            return "Accept"
        case let .other(value):
            return value
        }
    }
}

extension NetworkHTTPHeaderValues: Hashable {
    var description: String {
        switch self {
        case .json:
            return "application/json"
        case let .other(value):
            return value
        }
    }
}
