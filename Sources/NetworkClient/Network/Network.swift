import Combine
import Foundation

public enum SessionConfiguration {
    case `default`(queue: OperationQueue? = nil)
    case background(identifer: String, queue: OperationQueue? = nil)
    case ephemeral(queue: OperationQueue? = nil)
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

    public convenience init(
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

// MARK: Network Requests

extension Network: NetworkProtocol {
    public func serialRequests(for requests: [NetworkRequestProtocol], receive: DispatchQueue) -> PassthroughSubject<Data?, NetworkError> {
        let subject: PassthroughSubject<Data?, NetworkError> = .init()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "SerialRequests")
        let semaphore = DispatchSemaphore(value: 0)

        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            for request in requests {
                group.enter()
                do {
                    let request = try request.makeRequest()
                    self.makeRequest(request: request, receive: receive)
                        .sink(receiveCompletion: { result in
                            switch result {
                            case let .failure(error):
                                subject.send(completion: .failure(error))
                            default:
                                break
                            }
                        }, receiveValue: {
                            semaphore.signal()
                            group.leave()
                            subject.send($0)
                        })
                        .store(in: &self.cancellable)
                    semaphore.wait()
                } catch let error as NSError {
                    subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
                }
            }
        }

        group.notify(queue: queue) {
            subject.send(completion: .finished)
        }
        return subject
    }

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

    public func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        receive: DispatchQueue
    ) -> AnyPublisher<T, NetworkError> where T: Decodable {
        do {
            let request = try request.makeRequest()
            return makeRequest(request: request, receive: receive)
                .tryMap { data in
                    try NetworkError.dataDecoding(codable: T.self, data: data)
                }
                .mapError({ error in
                    guard let error = error as? NetworkError else {
                        return NetworkError.convertErrorToNetworkError(error: error as NSError)
                    }
                    return error
                })
                .eraseToAnyPublisher()
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
            session.downloadTask(with: downloadRequest).resumeTask()
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
            case let .data(data):
                session.uploadTask(
                    with: uploadRequest,
                    from: data
                ).resumeTask()
            case let .url(url):
                session.uploadTask(
                    with: uploadRequest,
                    fromFile: url
                ).resumeTask()
            }
            return delegate.uploadProgressSubject

        } catch let error as NSError {
            let failure = PassthroughSubject<UploadNetworkResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }

    public func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<UploadNetworkResponse, NetworkError> {
        do {
            let multipartRequest = try request.makeRequest()
            delegate.requestType = .upload
            session.uploadTask(with: multipartRequest, from: request.makeFormBody()).resumeTask()
            return delegate.uploadProgressSubject
        } catch let error as NSError {
            let failure = PassthroughSubject<UploadNetworkResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
}

// MARK: Cancel Tasks

extension Network {
    public func suspendRequest(request: URLRequest) {
        session.getAllTasks { task in
            task
                .filter { $0.state == .running }
                .filter { $0.originalRequest == request }.first?
                .suspend()
        }
    }

    public func resumeRequest(request: URLRequest) {
        session.getAllTasks { task in
            task
                .filter { $0.state == .suspended }
                .filter { $0.originalRequest == request }.first?
                .resume()
        }
    }

    public func cancelRequest(request: URLRequest) {
        session.getAllTasks { task in
            task
                .filter { $0.state == .running }
                .filter { $0.originalRequest == request }.first?
                .cancel()
        }
    }

    public func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void) {
        session.getAllTasks(completionHandler: completionHandler)
    }

    public func cancelAllRequests() {
        session.flush {
            debugPrint("Removed all requests from NetworkClient")
        }
    }
}
