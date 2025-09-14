import Foundation

@available(iOS 11.0, *)
public extension TraditionalNetwork {
    func suspend(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        guard let requestURL = request.urlComponents?.url else {
            completion(.failure(.badUrl))
            return
        }

        session.getAllTasks { tasks in
            if let task = tasks.first(where: { $0.originalRequest?.url == requestURL }) {
                task.suspend()
                completion(.success(true))
            } else {
                completion(.failure(.badUrl))
            }
        }
    }

    func resume(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        guard let requestURL = request.urlComponents?.url else {
            completion(.failure(.badUrl))
            return
        }

        session.getAllTasks { tasks in
            if let task = tasks.first(where: { $0.originalRequest?.url == requestURL }) {
                task.resume()
                completion(.success(true))
            } else {
                completion(.failure(.badUrl))
            }
        }
    }

    func cancel(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        guard let requestURL = request.urlComponents?.url else {
            completion(.failure(.badUrl))
            return
        }

        session.getAllTasks { tasks in
            if let task = tasks.first(where: { $0.originalRequest?.url == requestURL }) {
                task.cancel()
                completion(.success(true))
            } else {
                completion(.failure(.badUrl))
            }
        }
    }

    func cancelRequests(
        for requests: [NetworkRequestProtocol],
        completion: @escaping ([(URL, NetworkError?)]) -> Void
    ) {
        let requestURLs = requests.compactMap { $0.urlComponents?.url }
        guard !requestURLs.isEmpty else {
            completion([(URL(string: "InvalidURL")!, .badUrl)])
            return
        }

        session.getAllTasks { tasks in
            var results: [(URL, NetworkError?)] = []
            for task in tasks {
                if let taskURL = task.originalRequest?.url {
                    if requestURLs.contains(taskURL) {
                        task.cancel()
                        results.append((taskURL, nil))
                    } else {
                        results.append((taskURL, .badUrl))
                    }
                }
            }
            completion(results)
        }
    }

    func cancelAllRequests(completion: @escaping ([(URL, NetworkError?)]) -> Void) {
        session.getAllTasks { tasks in
            var results: [(URL, NetworkError?)] = []
            for task in tasks {
                if let taskURL = task.originalRequest?.url {
                    task.cancel()
                    results.append((taskURL, nil))
                }
            }
            completion(results)
        }
    }
}
