import Combine
import Foundation

public enum SessionConfiguration {
    case `default`(queue: OperationQueue? = nil)
    case background(identifer: String, queue: OperationQueue? = nil)
    case ephemeral(queue: OperationQueue? = nil)
}

public final class Network {
    private(set) var session: URLSessionProtocol
    private(set) var delegate: NetworkSessionDelegate
    private(set) var logger: NetworkLoggerProtocol?
    private(set) var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    
    var socketTask: URLSessionWebSocketTaskProtocol?
    var cancellable = Set<AnyCancellable>()
    public static var isInternetReachable: Bool {
        NetworkReachability.shared.isReachable
    }

    private init(
        session: URLSessionProtocol,
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

// MARK: Network Intializers

public extension Network {
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
                session: URLSession.defaultSession(delegate: delegate, queue: queue),
                logger: logger,
                delegate: delegate
            )
        case let .background(identifer, queue):
            self.init(
                session: URLSession.backgroundSession(
                    delegate: delegate,
                    identifier: identifer,
                    queue: queue
                ),
                logger: logger,
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(delegate: delegate, queue: queue),
                logger: logger,
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
                session: URLSession.defaultSession(delegate: delegate, queue: queue),
                logger: nil,
                delegate: delegate
            )
        case let .background(identifer, queue):
            self.init(
                session: URLSession.backgroundSession(
                    delegate: delegate,
                    identifier: identifer,
                    queue: queue
                ),
                logger: nil,
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(delegate: delegate, queue: queue),
                logger: nil,
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
                session: URLSession.defaultSession(delegate: delegate, queue: queue),
                logger: nil,
                delegate: delegate
            )
        case let .background(identifer, queue):
            self.init(
                session: URLSession.backgroundSession(
                    delegate: delegate,
                    identifier: identifer,
                    queue: queue
                ),
                logger: nil,
                delegate: delegate
            )
        case let .ephemeral(queue):
            self.init(
                session: URLSession.ephemeralSession(delegate: delegate, queue: queue),
                logger: nil,
                delegate: delegate
            )
        }
    }
}

// MARK: Request, Upload, Download, URLSessionTask, WebSocket

extension Network: NetworkProtocol {}
