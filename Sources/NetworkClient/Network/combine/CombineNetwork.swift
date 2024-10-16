import Combine
import Foundation

public enum SessionConfiguration {
    case `default`(queue: OperationQueue? = nil)
    case background(identifier: String, queue: OperationQueue? = nil)
    case ephemeral(queue: OperationQueue? = nil)
    case cache(queue: OperationQueue? = nil)
}

@available(iOS 13.0, *)
public final class CombineNetwork {
    private(set) var session: URLSessionCombineProtocol
    private(set) var delegate: NetworkSessionDelegate
    private(set) var logger: NetworkLoggerProtocol?
    private(set) var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    var isConnected: Bool = false
    var cancellable = Set<AnyCancellable>()
    var socketTask: URLSessionWebSocketTaskProtocol?
    public static let isInternetReachable: Bool =         NetworkReachability.shared.isReachable

    private init(
        session: URLSessionCombineProtocol,
        logger: NetworkLoggerProtocol? = nil,
        delegate: NetworkSessionDelegate,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        self.session = session
        self.logger = logger
        self.delegate = delegate
        self.urlSessionDidFinishEvents = urlSessionDidFinishEvents
    }

    // Helper method to create session
    private static func createSession(
        for config: SessionConfiguration,
        delegate: NetworkSessionDelegate
    ) -> URLSessionCombineProtocol {
        switch config {
        case let .default(queue):
            return URLSession.defaultSession(
                delegate: delegate,
                queue: queue
            )
        case let .background(identifier, queue):
            return URLSession.backgroundSession(
                delegate: delegate,
                identifier: identifier,
                queue: queue
            )
        case let .ephemeral(queue):
            return URLSession.ephemeralSession(
                delegate: delegate,
                queue: queue
            )
        case let .cache(queue):
            return URLSession.cacheSession(
                delegate: delegate,
                queue: queue
            )
        }
    }
}

// MARK: Network Initializers

public extension CombineNetwork {
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
        let session = Self.createSession(
            for: config,
            delegate: delegate
        )
        self.init(
            session: session,
            logger: logger,
            delegate: delegate
        )
    }

    convenience init(
        config: SessionConfiguration,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = NetworkSessionDelegate(urlSessionDidFinishEvents: urlSessionDidFinishEvents)
        let session = Self.createSession(
            for: config,
            delegate: delegate
        )
        self.init(
            session: session,
            logger: nil,
            delegate: delegate
        )
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
        let session = Self.createSession(
            for: config,
            delegate: delegate
        )
        self.init(
            session: session,
            logger: nil,
            delegate: delegate
        )
    }
}

// MARK: Request, Upload, Download, URLSessionTask, WebSocket

extension CombineNetwork: CombineNetworkProtocol {}
