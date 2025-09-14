
import Foundation
import Combine

@available(iOS 15.0, *)
extension AsyncNetwork {
    public func start(for request: NetworkRequestProtocol) async throws -> Bool {
        do {
            let urlRequest = try request.makeRequest()
            self.socketTask = self.session.webSocketTask(with: urlRequest)
            self.socketTask?.resume()

            // Wait for the socket to connect
            try await waitForClosure()

            return self.delegate.isSocketConnected
        } catch let error as NSError {
            throw NetworkError.convertErrorToNetworkError(error: error)
        }
    }

    public func send(message: NetworkSocketMessage) async throws -> Bool {
        guard self.delegate.isSocketConnected,
              let socketTask = self.socketTask else {
            throw NetworkError.socketDisconnected
        }

        let sessionMessage: URLSessionWebSocketTask.Message
        switch message {
        case let .text(text):
            sessionMessage = .string(text)
        case let .data(data):
            sessionMessage = .data(data)
        }

        // Use a continuation to wait for the sending confirmation
        return try await withCheckedThrowingContinuation { continuation in
            socketTask.send(sessionMessage) { error in
                if let error = error {
                    continuation.resume(throwing: NetworkError.convertErrorToNetworkError(error: error as NSError))
                } else {
                    continuation.resume(returning: true) // Return true on success
                }
            }
        }
    }

    public func receive() async throws -> NetworkSocketMessage {
        guard self.delegate.isSocketConnected,
              let socketTask = self.socketTask else {
            throw NetworkError.socketDisconnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            socketTask.receive { result in
                switch result {
                case let .success(message):
                    switch message {
                    case let .data(data):
                        continuation.resume(returning: .data(data))
                    case let .string(text):
                        continuation.resume(returning: .text(text))
                    @unknown default:
                        continuation.resume(throwing: NetworkError.unknown)
                    }
                case let .failure(error):
                    continuation.resume(throwing: NetworkError.convertErrorToNetworkError(error: error as NSError))
                }
            }
        }
    }

    public func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: String?
    ) async throws -> Bool {
        // Attempt to encode the reason
        guard let reasonMessage = reason?.data(using: .utf8) else {
            throw NetworkError.unableToCloseSocket // Throw an error if the reason is nil
        }

        // Check if the socket is already disconnected
        if !self.delegate.isSocketConnected {
            return false // Socket is already closed
        }

        // Perform the cancellation
        self.socketTask?.cancel(with: closeCode, reason: reasonMessage)
        
        // Clean up
        self.socketTask = nil
        
        // Wait for the closure confirmation
        try await waitForClosure()
        
        return true // Indicate that the socket was successfully closed
    }
}

@available(iOS 15.0, *)
private extension AsyncNetwork {
    func waitForClosure() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let timeout: TimeInterval = 5.0
            let deadline = Date().addingTimeInterval(timeout)

            // Use a timer to check periodically if the socket is closed
            let timer = Timer.scheduledTimer(
                withTimeInterval: 0.1,
                repeats: true
            ) { timer in
                if !self.delegate.isSocketConnected {
                    timer.invalidate()
                    continuation.resume(returning: ())
                } else if Date() > deadline {
                    timer.invalidate()
                    continuation.resume(throwing: NetworkError.socketClosureTimeout)
                }
            }
            
            // Add the timer to the run loop
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}
