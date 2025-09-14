import Foundation

@available(iOS 13.0, *)
public final class TraditionalURLSessionWebSocket: WebSocketProtocol {
    private var webSocketTask: URLSessionWebSocketTaskProtocol?
    private let urlSession: URLSessionWebSocketProtocol
    private var streamLock = os_unfair_lock_s()
    private let operationQueue = OperationQueue()

    public init(urlSession: URLSessionWebSocketProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }

    public func start(
        for request: NetworkSocketRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        guard NetworkMonitor.shared.isInternetReachable else {
            completion(.failure(.noInternet))
            return
        }

        guard let host = request.host else {
            completion(.failure(.invalidHost))
            return
        }
        
        guard let port = request.port else {
            completion(.failure(.invalidPort))
            return
        }

        let urlString = "ws://\(host):\(port)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.badRequestConstructed))
            return
        }

        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock)
            defer { os_unfair_lock_unlock(&self.streamLock) }

            self.webSocketTask = self.urlSession.webSocketTask(with: url)
            self.webSocketTask?.resume()
            completion(.success(true))
        }

        operationQueue.addOperation(operation)
    }

    public func send(
        message: Data,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        guard let task = webSocketTask else {
            completion(.failure(.socketConnectionFailure))
            return
        }

        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock)
            defer { os_unfair_lock_unlock(&self.streamLock) }

            let messageToSend = URLSessionWebSocketTask.Message.data(message)
            task.send(messageToSend) { error in
                if let error = error {
                    completion(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                } else {
                    completion(.success(true))
                }
            }
        }

        operationQueue.addOperation(operation)
    }

    public func receive(
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        guard let task = webSocketTask else {
            completion(.failure(.socketConnectionFailure))
            return
        }

        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock)
            defer { os_unfair_lock_unlock(&self.streamLock) }

            task.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                        completion(.success(data))
                    case .string(let string):
                        completion(.success(Data(string.utf8)))
                    @unknown default:
                        completion(.failure(.unknown))
                    }
                case .failure(let error):
                    completion(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                }
            }
        }

        operationQueue.addOperation(operation)
    }

    public func cancel(
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        let operation = BlockOperation {
            os_unfair_lock_lock(&self.streamLock)
            defer { os_unfair_lock_unlock(&self.streamLock) }

            self.webSocketTask?.cancel(with: .goingAway, reason: nil)
            self.webSocketTask = nil
            completion(.success(true))
        }

        operationQueue.addOperation(operation)
    }
}
