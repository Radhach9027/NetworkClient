import Foundation

extension URLSession {
    static func defaultSession(delegate: URLSessionDelegate, queue: OperationQueue? = nil) -> URLSession {
        URLSession(
            configuration: .defaultConfig,
            delegate: delegate,
            delegateQueue: queue
        )
    }

    static func backgroundSession(
        delegate: URLSessionDelegate,
        identifier: String,
        queue: OperationQueue? = nil
    ) -> URLSession {
        URLSession(
            configuration: .backgroundConfig(identifier),
            delegate: delegate,
            delegateQueue: queue
        )
    }

    static func ephemeralSession(delegate: URLSessionDelegate, queue: OperationQueue? = nil) -> URLSession {
        URLSession(
            configuration: .ephemeral,
            delegate: delegate,
            delegateQueue: queue
        )
    }
}
