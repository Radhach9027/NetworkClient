import Combine
import Foundation

// MARK: Network Requests

public extension Network {
    func serialRequests(for requests: [NetworkRequestProtocol], receive: DispatchQueue) -> PassthroughSubject<Data?, NetworkError> {
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

    func request(
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

    func request<T>(
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
