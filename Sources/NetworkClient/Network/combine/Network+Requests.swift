import Combine
import Foundation

// MARK: Network Requests

public extension CombineNetwork {
    func serialRequests(for requests: [NetworkRequestProtocol], receive: DispatchQueue) -> AnyPublisher<Data?, NetworkError> {
        let publishers: [AnyPublisher<Data?, NetworkError>] = requests.compactMap { request in
            do {
                let urlRequest = try request.makeRequest()
                return self.makeRequest(request: urlRequest, receive: receive)
                    .map { $0 as Data? } // Convert Data to Data?
                    .catch { error in
                        // Handle error and return a nil value for failed requests
                        Just(nil).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            } catch let error as NSError {
                // Return a publisher that emits the error if request creation fails
                return Fail(error: NetworkError.convertErrorToNetworkError(error: error)).eraseToAnyPublisher()
            }
        }
        
        // Merge all publishers and collect results
        return Publishers.MergeMany(publishers)
            .collect() // Collect results into an array
            .map { $0.first ?? nil } // Return the first result or nil
            .eraseToAnyPublisher() // Convert to AnyPublisher
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
    
    func concurrentRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) -> AnyPublisher<[Data?], NetworkError> {
        let publishers: [AnyPublisher<Data?, NetworkError>] = requests.compactMap { request in
            do {
                let urlRequest = try request.makeRequest()
                return self.makeRequest(request: urlRequest, receive: receive)
                    .map { $0 as Data? } // Convert Data to Data?
                    .catch { error in
                        // Handle error and return a nil value for failed requests
                        Just(nil).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            } catch let error as NSError {
                // Return a publisher that emits the error if request creation fails
                return Fail(error: NetworkError.convertErrorToNetworkError(error: error)).eraseToAnyPublisher()
            }
        }
        
        // Merge all publishers and collect results into an array
        return Publishers.MergeMany(publishers)
            .collect() // Collect results into an array
            .eraseToAnyPublisher() // Convert to AnyPublisher
    }
}

private extension CombineNetwork {
    func makeRequest(request: URLRequest, receive: DispatchQueue) -> AnyPublisher<Data, NetworkError> {
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
