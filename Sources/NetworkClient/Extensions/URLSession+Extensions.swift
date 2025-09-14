import Foundation

@available(iOS 11.0, *)
public extension URLSession {
    static func defaultSession(
        delegate: URLSessionDelegate? = nil,
        queue: OperationQueue? = nil
    ) -> URLSession {
        URLSession(
            configuration: .defaultConfig,
            delegate: delegate,
            delegateQueue: queue
        )
    }
    
    static func sessionWithCustomTimeouts(
        delegate: URLSessionDelegate? = nil,
        queue: OperationQueue? = nil,
        timeoutIntervalForRequest: Double = 5.0,
        timeoutIntervalForResource: Double = 10.0
    ) -> URLSession {
        URLSession(
            configuration: .intervalConfig(timeoutIntervalForRequest, timeoutIntervalForResource),
            delegate: delegate,
            delegateQueue: queue
        )
    }

    static func backgroundSession(
        delegate: URLSessionDelegate? = nil,
        identifier: String,
        queue: OperationQueue? = nil
    ) -> URLSession {
        URLSession(
            configuration: .backgroundConfig(identifier),
            delegate: delegate,
            delegateQueue: queue
        )
    }

    static func ephemeralSession(
        delegate: URLSessionDelegate? = nil,
        queue: OperationQueue? = nil
    ) -> URLSession {
        URLSession(
            configuration: .ephemeral,
            delegate: delegate,
            delegateQueue: queue
        )
    }

    static func cacheSession(
        delegate: URLSessionDelegate? = nil,
        queue: OperationQueue? = nil
    ) -> URLSession {
        return URLSession(
            configuration: .cache,
            delegate: delegate,
            delegateQueue: queue
        )
    }
}
