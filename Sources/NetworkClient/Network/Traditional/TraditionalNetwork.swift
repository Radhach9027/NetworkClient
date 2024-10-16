import Combine
import Foundation

@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
public final class TraditionalNetwork {
    private(set) var requestInterceptors: [TraditionalNetworkRequestInterceptor] = []
    private(set) var retryInterceptors: [TraditionalNetworkRetryInterceptor] = []
    private(set) var session: URLSessionTraditionalProtocol
    private(set) var delegate: NetworkSessionDelegate
    private(set) var logger: NetworkLoggerProtocol?
    private(set) var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    public static let isInternetReachable: Bool =         NetworkReachability.shared.isReachable
    var socketTask: URLSessionWebSocketTaskProtocol?
    var cancellable = Set<AnyCancellable>()
    
    private init(
        session: URLSessionTraditionalProtocol,
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

// MARK: TraditionalNetwork Interceptors
@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
public extension TraditionalNetwork {
    func add(requestInterceptor: TraditionalNetworkRequestInterceptor) {
        requestInterceptors.append(requestInterceptor)
    }

    func add(retryInterceptor: TraditionalNetworkRetryInterceptor) {
        retryInterceptors.append(retryInterceptor)
    }
}

// MARK: TraditionalNetwork Intializers
@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
public extension TraditionalNetwork {
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

@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
extension TraditionalNetwork: TraditionalNetworkProtocol {}

