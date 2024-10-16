import Combine
import Foundation

@available(iOS 13.0, *)
extension CombineNetwork {
    public func start(for request: NetworkRequestProtocol) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            do {
                let urlRequest = try request.makeRequest()
                self.socketTask = self.session.webSocketTask(with: urlRequest)
                self.socketTask?.resume()
                
                // Wait for the socket to connect
                self.waitForClosure()
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                promise(.success(self.delegate.isSocketConnected))
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { }
                    )
                    .store(in: &self.cancellable)
                
            } catch let error as NSError {
                promise(.failure(NetworkError.convertErrorToNetworkError(error: error)))
            }
        }
        .eraseToAnyPublisher()
    }

    public func send(message: NetworkSocketMessage) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            guard self.delegate.isSocketConnected,
                  let socketTask = self.socketTask else {
                promise(.failure(NetworkError.socketDisconnected))
                return
            }

            let sessionMessage: URLSessionWebSocketTask.Message
            switch message {
            case let .text(text):
                sessionMessage = .string(text)
            case let .data(data):
                sessionMessage = .data(data)
            }

            socketTask.send(sessionMessage) { error in
                if let error = error {
                    promise(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                } else {
                    promise(.success(true)) // Return true on success
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func receive() -> AnyPublisher<NetworkSocketMessage, Error> {
        Future<NetworkSocketMessage, Error> { promise in
            guard self.delegate.isSocketConnected,
                  let socketTask = self.socketTask else {
                promise(.failure(NetworkError.socketDisconnected))
                return
            }

            socketTask.receive { result in
                switch result {
                case let .success(message):
                    switch message {
                    case let .data(data):
                        promise(.success(.data(data)))
                    case let .string(text):
                        promise(.success(.text(text)))
                    @unknown default:
                        promise(.failure(NetworkError.unknown))
                    }
                case let .failure(error):
                    promise(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: String?
    ) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            // Attempt to encode the reason
            guard let reasonMessage = reason?.data(using: .utf8) else {
                promise(.failure(NetworkError.unableToCloseSocket))
                return
            }

            // Check if the socket is already disconnected
            if !self.delegate.isSocketConnected {
                promise(.success(false)) // Socket is already closed
                return
            }

            // Perform the cancellation
            self.socketTask?.cancel(with: closeCode, reason: reasonMessage)

            // Clean up
            self.socketTask = nil
            
            // Wait for the closure confirmation
            self.waitForClosure()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            promise(.success(true)) // Indicate that the socket was successfully closed
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { }
                )
                .store(in: &self.cancellable)
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
private extension CombineNetwork {
    func waitForClosure() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            let timeout: TimeInterval = 5.0
            let deadline = Date().addingTimeInterval(timeout)

            // Use a timer to check periodically if the socket is closed
            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if !self.delegate.isSocketConnected {
                    timer.invalidate()
                    promise(.success(()))
                } else if Date() > deadline {
                    timer.invalidate()
                    promise(.failure(NetworkError.socketClosureTimeout))
                }
            }
            
            // Add the timer to the run loop
            RunLoop.current.add(timer, forMode: .common)
        }
        .eraseToAnyPublisher()
    }
}
