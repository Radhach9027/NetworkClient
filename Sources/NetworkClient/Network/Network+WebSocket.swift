import Combine
import Foundation

public extension Network {
     func start(for request: NetworkRequestProtocol, completion: @escaping (NetworkError?) -> Void) {
        do {
            let request = try request.makeRequest()
            socketTask = session.webSocketTask(with: request)
            socketTask?.resume()
        } catch let error as NSError {
            completion(NetworkError.convertErrorToNetworkError(error: error))
        }
    }

    func send(message: NetworkSocketMessage, completion: @escaping ((NetworkError?) -> Void)) {
        switch message {
        case let .text(text):
            socketTask?.send(.string(text), completionHandler: { error in
                if let error = error as? NSError {
                    completion(NetworkError.convertErrorToNetworkError(error: error))
                }
                completion(nil)
            })
        case let .data(data):
            socketTask?.send(.data(data), completionHandler: { error in
                if let error = error as? NSError {
                    completion(NetworkError.convertErrorToNetworkError(error: error))
                }
                completion(nil)
            })
        }
    }

    func receive() -> PassthroughSubject<NetworkSocketMessage, NetworkError> {
        let subject = PassthroughSubject<NetworkSocketMessage, NetworkError>()
        socketTask?.receive { result in
            switch result {
            case let .success(message):
                switch message {
                case let .data(data):
                    subject.send(.data(data))
                case let .string(text):
                    subject.send(.text(text))
                @unknown default:
                    subject.send(completion: .failure(.unknown))
                }
            case let .failure(error):
                subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
            }
        }
        return subject
    }

    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: String?) {
        let reasonMessage = reason?.data(using: .utf8)
        socketTask?.cancel(with: closeCode, reason: reasonMessage)
    }
}
