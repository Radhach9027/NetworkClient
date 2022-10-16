import Foundation
import Combine

public enum SessionConfiguration {
    case `default`
    case background
}

public final class Network {
    private var session: URLSessionProtocol
    private var delegate: NetworkSessionDelegate
    private var logger: NetworkLoggerProtocol?
    private var cancellable = Set<AnyCancellable>()
    public static var isInternetReachable: Bool {
        NetworkReachability.shared.isReachable
    }
    
    private init(
        session: URLSessionProtocol,
        logger: NetworkLoggerProtocol? = nil,
        delegate: NetworkSessionDelegate
    ) {
        self.session = session
        self.logger = logger
        self.delegate = delegate
    }
}

extension Network {
    
    public convenience init(
        config: SessionConfiguration,
        pinning: SSLPinning,
        logger: NetworkLoggerProtocol
    ) {
        let delegate = NetworkSessionDelegate(pinning: pinning)
        switch config {
            case .default:
                self.init(
                    session: URLSession.defaultSession(delegate: delegate),
                    logger: logger,
                    delegate: delegate
                )
            case .background:
                self.init(
                    session:  URLSession.backgroundSession(delegate: delegate),
                    logger: logger,
                    delegate: delegate
                )
        }
    }
    
    public convenience init(config: SessionConfiguration) {
        let delegate = NetworkSessionDelegate()
        switch config {
            case .default:
                self.init(
                    session: URLSession.defaultSession(delegate: delegate),
                    logger: nil,
                    delegate: delegate
                )
            case .background:
                self.init(
                    session:  URLSession.backgroundSession(delegate: delegate),
                    logger: nil,
                    delegate: delegate
                )
        }
    }
    
    public convenience init(
        config: SessionConfiguration,
        pinning: SSLPinning
    ) {
        let delegate = NetworkSessionDelegate(pinning: pinning)
        switch config {
            case .default:
                self.init(
                    session: URLSession.defaultSession(delegate: delegate),
                    logger: nil,
                    delegate: delegate
                )
            case .background:
                self.init(
                    session:  URLSession.backgroundSession(delegate: delegate),
                    logger: nil,
                    delegate: delegate
                )
        }
    }
}

extension Network: NetworkProtocol {

    public func request(
        for request: URLRequest,
        receive: DispatchQueue
    ) -> AnyPublisher<Data, NetworkError> {
        
        session.dataTaskPublisher(for: request)
            .receive(on: receive)
            .tryMap { [weak self] (data, response) in
                guard let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse) else {
                    return data
                }
                
                if let logger = self?.logger {
                    logger.logRequest(
                        url: request.url!,
                        error: error,
                        type: .error,
                        privacy: .encrypt
                    )
                }
                
                throw error
            }
            .mapError { [weak self] error in
                guard let error = error as? NetworkError else {
                    return NetworkError.convertErrorToNetworkError(error: error as NSError)
                }
                
                if let logger = self?.logger {
                    logger.logRequest(
                        url: request.url!,
                        error: error,
                        type: .error,
                        privacy: .encrypt
                    )
                }
                
                return error
            }
            .eraseToAnyPublisher()
    }
    
    public func request(
        for url: URL,
        receive: DispatchQueue
    ) -> AnyPublisher<Data, NetworkError> {
        
        session.dataTaskPublisher(for: url)
            .receive(on: receive)
            .tryMap { [weak self] (data, response) in
                guard let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse) else {
                    return data
                }
                
                if let logger = self?.logger {
                    logger.logRequest(
                        url: url,
                        error: error,
                        type: .error,
                        privacy: .encrypt
                    )
                }
                
                throw error
            }
            .mapError { [weak self] error in
                guard let error = error as? NetworkError else {
                    return NetworkError.convertErrorToNetworkError(error: error as NSError)
                }
                
                if let logger = self?.logger {
                    logger.logRequest(
                        url: url,
                        error: error,
                        type: .error,
                        privacy: .encrypt
                    )
                }
                
                return error
            }
            .eraseToAnyPublisher()
    }
}

// MARK: Download Tasks
extension Network {
    
    public func download(
        for request: URLRequest,
        receive: DispatchQueue
    ) -> PassthroughSubject<DownloadNetworkResponse, NetworkError> {
        session.downloadTask(with: request).resumeBackgroundTask()
        return delegate.progressSubject
    }
    
    public func download(
        for url: URL,
        receive: DispatchQueue
    ) -> PassthroughSubject<DownloadNetworkResponse, NetworkError> {
        session.downloadTask(with: URLRequest(url: url)).resumeBackgroundTask()
        return delegate.progressSubject
    }
    
    public func download(
        to location: URL,
        for url: URL,
        receive: DispatchQueue
    ) -> PassthroughSubject<DownloadNetworkResponse, NetworkError> {
        delegate.saveToLocation = location
        session.downloadTask(with: URLRequest(url: url)).resumeBackgroundTask()
        return delegate.progressSubject
    }
}

// MARK: Cancel Tasks
extension Network {
    
    public func cancelAllTasks() {
        session.invalidateAndCancel()
    }
    
    public func cancelTaskWithUrl(url: URL) {
        session.getAllTasks { task in
            task
                .filter { $0.state == .running }
                .filter { $0.originalRequest?.url == url }.first?
                .cancel()
        }
    }
}

// TODO: Development in-progress

/*
// MARK: Bulk Tasks
extension Network {
    
    func bulkRequest(for requests: [URLRequest],
                     receive: DispatchQueue) -> AnyPublisher<[Publishers.MergeMany<AnyPublisher<Data, NetworkError>.Output>]> {
        
        return Just(requests)
            .setFailureType(to: NetworkError.self)
            .flatMap { (values) -> Publishers.MergeMany<AnyPublisher<Data, NetworkError>> in
                let tasks = values.map { (request) -> AnyPublisher<Data, NetworkError> in
                    return self.request(for: request, receive: receive)
                }
                return Publishers.MergeMany(tasks)
            }.collect()
            .eraseToAnyPublisher()
    }
}
*/
