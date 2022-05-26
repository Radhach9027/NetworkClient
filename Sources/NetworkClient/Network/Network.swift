import Foundation
import Combine

public final class Network {
    
    private var session: URLSessionProtocol
    private var sessionDelegate: NetworkSessionDelegateProtocol?
    private var logger: NetworkLoggerProtocol?
    public static var isInternetReachable: Bool {
        NetworkReachability.shared.isReachable
    }
    
    public init(session: URLSessionProtocol = URLSession.shared,
         logger: NetworkLoggerProtocol? = nil) {
        self.session = session
        self.logger = logger
    }
}

extension Network {
    
    public convenience init(configuration: URLSessionConfiguration,
                     delegateQueue: OperationQueue) {
        
        let delegate = NetworkSessionDelegate()
        let session = URLSession(configuration: configuration,
                                 delegate: delegate,
                                 delegateQueue: delegateQueue)
        self.init(session: session)
    }

    public convenience init(configuration: URLSessionConfiguration,
                     delegateQueue: OperationQueue,
                     pinning: SSLPinning) {
        
        let delegate = NetworkSessionDelegate(pinning: pinning)
        let session = URLSession(configuration: configuration,
                                 delegate: delegate,
                                 delegateQueue: delegateQueue)
        self.init(session: session)
    }
    
    public convenience init(configuration: URLSessionConfiguration,
                     delegateQueue: OperationQueue,
                     pinning: SSLPinning,
                     logger: NetworkLoggerProtocol) {
        
        let delegate = NetworkSessionDelegate(pinning: pinning)
        let session = URLSession(configuration: configuration,
                                 delegate: delegate,
                                 delegateQueue: delegateQueue)
        self.init(session: session,
                  logger: logger)
    }
}

extension Network: NetworkProtocol {
    
    public func request(for request: URLRequest,
                 receive: DispatchQueue) -> AnyPublisher<Data, NetworkError> {
        
        session.dataTaskPublisher(for: request)
            .receive(on: receive)
            .tryMap { [weak self] (data, response) in
                guard let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse) else {
                    return data
                }
                
                if let logger = self?.logger {
                    logger.logRequest(url: request.url!,
                                      error: error,
                                      type: .error,
                                      privacy: .encrypt)
                }
                
                throw error
            }
            .mapError { [weak self] error in
                guard let error = error as? NetworkError else {
                    return NetworkError.convertErrorToNetworkError(error: error as NSError)
                }
                
                if let logger = self?.logger {
                    logger.logRequest(url: request.url!,
                                      error: error,
                                      type: .error,
                                      privacy: .encrypt)
                }
                
                return error
            }
            .eraseToAnyPublisher()
    }
    
    public func request(for url: URL,
                 receive: DispatchQueue) -> AnyPublisher<Data, NetworkError> {
        
        session.dataTaskPublisher(for: url)
            .receive(on: receive)
            .tryMap { [weak self] (data, response) in
                guard let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse) else {
                    return data
                }
                
                if let logger = self?.logger {
                    logger.logRequest(url: url,
                                      error: error,
                                      type: .error,
                                      privacy: .encrypt)
                }
                
                throw error
            }
            .mapError { [weak self] error in
                guard let error = error as? NetworkError else {
                    return NetworkError.convertErrorToNetworkError(error: error as NSError)
                }
                
                if let logger = self?.logger {
                    logger.logRequest(url: url,
                                      error: error,
                                      type: .error,
                                      privacy: .encrypt)
                }
                
                return error
            }
            .eraseToAnyPublisher()
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



// MARK: Upload Tasks
extension Network {
    
    func upload(with request: URLRequest,
                from bodyData: Data?,
                receive: DispatchQueue) -> AnyPublisher<UploadNetworkResponse, NetworkError> {
        
    }
    
    func upload(for request: URLRequest,
                fileURL: URL,
                receive: DispatchQueue) -> AnyPublisher<UploadNetworkResponse, NetworkError> {
        
    }
}

// MARK: Download Tasks
extension Network {
    
    func download(for request: URLRequest,
                  receive: DispatchQueue) -> AnyPublisher<DownloadNetworkResponse, NetworkError> {
        
    }
    
    func download(for url: URL,
                  receive: DispatchQueue) -> AnyPublisher<DownloadNetworkResponse, NetworkError> {
        
    }
}
*/
