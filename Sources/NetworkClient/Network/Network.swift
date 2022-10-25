import Combine
import Foundation

public enum SessionConfiguration {
    case `default`
    case background(identifer: String)
}

public final class Network {
    private var session: URLSessionProtocol
    private var delegate: NetworkSessionDelegate
    private var logger: NetworkLoggerProtocol?
    private var cancellable = Set<AnyCancellable>()
    private var urlSessionDidFinishEvents: ((URLSession) -> Void)?
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

extension Network {
    public convenience init(
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
        case .default:
            self.init(
                session: URLSession.defaultSession(delegate: delegate),
                logger: logger,
                delegate: delegate
            )
        case let .background(identifer):
            self.init(
                session: URLSession.backgroundSession(
                    delegate: delegate,
                    identifier: identifer
                ),
                logger: logger,
                delegate: delegate
            )
        }
    }

    public convenience init(
        config: SessionConfiguration,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = NetworkSessionDelegate(urlSessionDidFinishEvents: urlSessionDidFinishEvents)

        switch config {
        case .default:
            self.init(
                session: URLSession.defaultSession(delegate: delegate),
                logger: nil,
                delegate: delegate
            )
        case let .background(identifer):
            self.init(
                session: URLSession.backgroundSession(
                    delegate: delegate,
                    identifier: identifer
                ),
                logger: nil,
                delegate: delegate
            )
        }
    }

    public convenience init(
        config: SessionConfiguration,
        pinning: SSLPinning,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
    ) {
        let delegate = NetworkSessionDelegate(
            pinning: pinning,
            urlSessionDidFinishEvents: urlSessionDidFinishEvents
        )

        switch config {
        case .default:
            self.init(
                session: URLSession.defaultSession(delegate: delegate),
                logger: nil,
                delegate: delegate
            )
        case let .background(identifer):
            self.init(
                session: URLSession.backgroundSession(
                    delegate: delegate,
                    identifier: identifer
                ),
                logger: nil,
                delegate: delegate
            )
        }
    }
}

// MARK: Network Requests

extension Network: NetworkProtocol {
    public func request(
        for request: NetworkRequestProtocol,
        receive: DispatchQueue
    ) -> AnyPublisher<Data, NetworkError> {
        do {
            let request = try request.makeRequest()
            return makeRequest(request: request, receive: receive)

        } catch let error as NSError {
            return Fail(error: NetworkError.convertErrorToNetworkError(error: error))
                .eraseToAnyPublisher()
        }
    }
    
    private func makeRequest(request: URLRequest, receive: DispatchQueue) -> AnyPublisher<Data, NetworkError> {
        session.dataTaskPublisher(for: request)
            .receive(on: receive)
            .tryMap { [weak self] data, response in
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
}

// MARK: Download Tasks

extension Network {
    public func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<DownloadNetworkResponse, NetworkError> {
        do {
            let downloadRequest = try request.makeRequest()
            delegate.requestType = .download
            delegate.saveToLocation = request.saveDownloadedUrlToLocation
            session.downloadTask(with: downloadRequest).resumeBackgroundTask()
            return delegate.downloadProgressSubject
        } catch let error as NSError {
            let failure = PassthroughSubject<DownloadNetworkResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
}

// MARK: Upload Tasks

extension Network {
    public func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<UploadNetworkResponse, NetworkError> {
        do {
            let uploadRequest = try request.makeRequest()
            delegate.requestType = .upload
            switch request.uploadFile {
                case .data(let data):
                    session.uploadTask(
                        with: uploadRequest,
                        from: data
                    ).resumeBackgroundTask()
                case .url(let url):
                    session.uploadTask(
                        with: uploadRequest,
                        fromFile: url
                    ).resumeBackgroundTask()
            }
            return delegate.uploadProgressSubject

        } catch let error as NSError {
            let failure = PassthroughSubject<UploadNetworkResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
    
    public func uploadMultipart(
        for request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> AnyPublisher<Data, NetworkError> {
        do {
            let multipartRequest = try request.makeRequest()
            return makeRequest(request: multipartRequest, receive: receive)
        } catch let error as NSError {
            return Fail(error: NetworkError.convertErrorToNetworkError(error: error))
                .eraseToAnyPublisher()
        }
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
