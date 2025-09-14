import Foundation

@available(iOS 11.0, *)
public final class TraditionalNetwork {
    private(set) var requestInterceptors: [TraditionalNetworkRequestInterceptor] = []
    private(set) var retryInterceptors: [TraditionalNetworkRetryInterceptor] = []
    private(set) var session: URLSessionTraditionalProtocol
    private(set) var delegate: TraditionalNetworkSessionDelegate
    private(set) var logger: NetworkLoggerProtocol?
    private(set) var consoleLogger: NetworkConsoleLoggerProtocol?
    private(set) var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    public static let isInternetReachable: Bool = NetworkReachability.shared.isReachable

    private init(
        session: URLSessionTraditionalProtocol,
        logger: NetworkLoggerProtocol? = nil,
        consoleLogger: NetworkConsoleLoggerProtocol? = nil,
        delegate: TraditionalNetworkSessionDelegate,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        self.session = session
        self.logger = logger
        self.consoleLogger = consoleLogger
        self.delegate = delegate
        self.urlSessionDidFinishEvents = urlSessionDidFinishEvents
    }
}

// MARK: - TraditionalNetwork Initializers

@available(iOS 11.0, *)
public extension TraditionalNetwork {
    convenience init(
        config: SessionConfiguration,
        pinning: SSLPinning,
        logger: NetworkLoggerProtocol,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = TraditionalNetworkSessionDelegate(
            pinning: pinning,
            logger: logger,
            urlSessionDidFinishEvents: urlSessionDidFinishEvents
        )

        switch config {
        case let .default(queue):
            self.init(
                session: URLSession.defaultSession(queue: queue),
                logger: logger,
                delegate: delegate
            )

        case let .defaultWithCustomTimeOuts(
            identifier,
            queue,
            timeoutIntervalForRequest,
            timeoutIntervalForResource
        ):
            let session = URLSession.sessionWithCustomTimeouts(
                delegate: delegate,
                queue: queue,
                timeoutIntervalForRequest: timeoutIntervalForRequest,
                timeoutIntervalForResource: timeoutIntervalForResource
            )
            self.init(
                session: session,
                logger: logger,
                delegate: delegate
            )
        case let .background(identifier, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifier,
                    queue: queue
                ),
                logger: logger,
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(queue: queue),
                logger: logger,
                delegate: delegate
            )
        case let .cache(queue):
            self.init(
                session: URLSession.cacheSession(queue: queue),
                delegate: delegate
            )
        }
    }

    convenience init(
        config: SessionConfiguration,
        logger: NetworkLoggerProtocol,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = TraditionalNetworkSessionDelegate(
            logger: logger,
            urlSessionDidFinishEvents: urlSessionDidFinishEvents
        )

        switch config {
        case let .default(queue):
            self.init(
                session: URLSession.defaultSession(queue: queue),
                logger: logger,
                delegate: delegate
            )
        case let .defaultWithCustomTimeOuts(
            identifier,
            queue,
            timeoutIntervalForRequest,
            timeoutIntervalForResource
        ):
            let session = URLSession.sessionWithCustomTimeouts(
                delegate: delegate,
                queue: queue,
                timeoutIntervalForRequest: timeoutIntervalForRequest,
                timeoutIntervalForResource: timeoutIntervalForResource
            )
            self.init(
                session: session,
                logger: logger,
                delegate: delegate
            )
        case let .background(identifier, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifier,
                    queue: queue
                ),
                logger: logger,
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(queue: queue),
                logger: logger,
                delegate: delegate
            )
        case let .cache(queue):
            self.init(
                session: URLSession.cacheSession(queue: queue),
                delegate: delegate
            )
        }
    }

    convenience init(config: SessionConfiguration) {
        let delegate = TraditionalNetworkSessionDelegate()

        switch config {
        case let .default(queue):
            self.init(
                session: URLSession.defaultSession(queue: queue),
                delegate: delegate
            )
        case let .defaultWithCustomTimeOuts(
            _,
            queue,
            timeoutIntervalForRequest,
            timeoutIntervalForResource
        ):
            let session = URLSession.sessionWithCustomTimeouts(
                delegate: delegate,
                queue: queue,
                timeoutIntervalForRequest: timeoutIntervalForRequest,
                timeoutIntervalForResource: timeoutIntervalForResource
            )
            self.init(
                session: session,
                delegate: delegate
            )
        case let .background(identifier, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifier,
                    queue: queue
                ),
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(queue: queue),
                delegate: delegate
            )
        case let .cache(queue):
            self.init(
                session: URLSession.cacheSession(queue: queue),
                delegate: delegate
            )
        }
    }

    convenience init(
        config: SessionConfiguration,
        consoleLogger: NetworkConsoleLoggerProtocol
    ) {
        let delegate = TraditionalNetworkSessionDelegate()

        switch config {
        case let .default(queue):
            self.init(
                session: URLSession.defaultSession(queue: queue),
                consoleLogger: consoleLogger,
                delegate: delegate
            )
        case let .defaultWithCustomTimeOuts(
            identifier,
            queue,
            timeoutIntervalForRequest,
            timeoutIntervalForResource
        ):
            let session = URLSession.sessionWithCustomTimeouts(
                delegate: delegate,
                queue: queue,
                timeoutIntervalForRequest: timeoutIntervalForRequest,
                timeoutIntervalForResource: timeoutIntervalForResource
            )
            self.init(
                session: session,
                consoleLogger: consoleLogger,
                delegate: delegate
            )
        case let .background(identifier, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifier,
                    queue: queue
                ),
                consoleLogger: consoleLogger,
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(queue: queue),
                consoleLogger: consoleLogger,
                delegate: delegate
            )
        case let .cache(queue):
            self.init(
                session: URLSession.cacheSession(queue: queue),
                consoleLogger: consoleLogger,
                delegate: delegate
            )
        }
    }

    convenience init(
        config: SessionConfiguration,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = TraditionalNetworkSessionDelegate(
            urlSessionDidFinishEvents: urlSessionDidFinishEvents
        )

        switch config {
        case let .default(queue):
            self.init(
                session: URLSession.defaultSession(queue: queue),
                delegate: delegate
            )
        case let .defaultWithCustomTimeOuts(
            identifier,
            queue,
            timeoutIntervalForRequest,
            timeoutIntervalForResource
        ):
            let session = URLSession.sessionWithCustomTimeouts(
                delegate: delegate,
                queue: queue,
                timeoutIntervalForRequest: timeoutIntervalForRequest,
                timeoutIntervalForResource: timeoutIntervalForResource
            )
            self.init(
                session: session,
                delegate: delegate
            )
        case let .background(identifier, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifier,
                    queue: queue
                ),
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(queue: queue),
                delegate: delegate
            )
        case let .cache(queue):
            self.init(
                session: URLSession.cacheSession(queue: queue),
                delegate: delegate
            )
        }
    }
}

// MARK: - TraditionalNetwork Interceptors

@available(iOS 11.0, *)
public extension TraditionalNetwork {
    func add(requestInterceptor: TraditionalNetworkRequestInterceptor) {
        requestInterceptors.append(requestInterceptor)
    }

    func add(retryInterceptor: TraditionalNetworkRetryInterceptor) {
        retryInterceptors.append(retryInterceptor)
    }
}

// MARK: - Request, Upload, Download

@available(iOS 11.0, *)
extension TraditionalNetwork: TraditionalNetworkProtocol {}
