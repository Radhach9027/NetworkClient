import Combine
import Foundation

@available(iOS 15.0, *)
public final class AsyncNetwork {
    private(set) var requestInterceptors: [AsyncNetworkRequestInterceptor] = []
    private(set) var retryInterceptors: [AsyncNetworkRetryInterceptor] = []
    private(set) var session: URLSessionAsyncProtocol
    private(set) var delegate: NetworkSessionDelegate
    private(set) var logger: NetworkLoggerProtocol?
    private(set) var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    public static let isInternetReachable: Bool = NetworkReachability.shared.isReachable
    var socketTask: URLSessionWebSocketTaskProtocol?
    var cancellable = Set<AnyCancellable>()

    private init(
        session: URLSessionAsyncProtocol,
        logger: NetworkLoggerProtocol? = nil,
        delegate: NetworkSessionDelegate,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        self.session = session
        self.logger = logger
        self.delegate = delegate
        self.urlSessionDidFinishEvents = urlSessionDidFinishEvents
    }
}

@available(iOS 15.0, *)
public extension AsyncNetwork {
    func add(requestInterceptor: AsyncNetworkRequestInterceptor) {
        requestInterceptors.append(requestInterceptor)
    }

    func add(retryInterceptor: AsyncNetworkRetryInterceptor) {
        retryInterceptors.append(retryInterceptor)
    }
}

// MARK: AsyncNetwork Intializers

@available(iOS 15.0, *)
public extension AsyncNetwork {
    convenience init(
        config: SessionConfiguration,
        pinning: SSLPinning,
        logger: NetworkLoggerProtocol,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = NetworkSessionDelegate(
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
        case let .background(identifer, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifer,
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
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = NetworkSessionDelegate(urlSessionDidFinishEvents: urlSessionDidFinishEvents)

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
        case let .background(identifer, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifer,
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
        pinning: SSLPinning,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = NetworkSessionDelegate(
            pinning: pinning,
            urlSessionDidFinishEvents: urlSessionDidFinishEvents
        )

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
        case let .background(identifer, queue):
            self.init(
                session: URLSession.backgroundSession(
                    identifier: identifer,
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

// MARK: Request, Upload, Download, URLSessionTask, WebSocket
@available(iOS 15.0, *)
extension AsyncNetwork: AsyncNetworkProtocol {}
