import Combine
import Foundation

// MARK: URLSession Tasks

public extension Network {
    func suspend(for request: URLRequest) {
        session.getAllTasks { task in
            task
                .filter { $0.state == .running }
                .filter { $0.originalRequest == request }.first?
                .suspend()
        }
    }

    func resume(for request: URLRequest) {
        session.getAllTasks { task in
            task
                .filter { $0.state == .suspended }
                .filter { $0.originalRequest == request }.first?
                .resume()
        }
    }

    func cancel(for request: URLRequest) {
        session.getAllTasks { task in
            task
                .filter { $0.state == .running }
                .filter { $0.originalRequest == request }.first?
                .cancel()
        }
    }

    func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void) {
        session.getAllTasks(completionHandler: completionHandler)
    }

    func cancelAllRequests() {
        session.flush {
            debugPrint("Removed all requests from NetworkClient")
        }
    }
}
