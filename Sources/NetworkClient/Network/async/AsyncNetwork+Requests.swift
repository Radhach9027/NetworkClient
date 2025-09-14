import Combine
import Foundation

@available(iOS 15.0, *)
extension AsyncNetwork {
    public func request(
        request: NetworkRequestProtocol,
        receive: DispatchQueue
    ) async throws -> AnyPublisher<Data, NetworkError> {
        var urlRequest = try request.makeRequest()
        
        // Apply request interceptors
        for interceptor in requestInterceptors {
            try await interceptor.adapt(&urlRequest)
        }
        
        return Future<Data, NetworkError> { promise in
            receive.async {
                Task {
                    let localUrlRequest = urlRequest // Capture a local copy
                    do {
                        let (data, response) = try await self.session.data(
                            for: localUrlRequest,
                            delegate: self.delegate
                        )
                        
                        // Validate HTTP response
                        if let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse, responseData: data) {
                            promise(.failure(error))
                        } else {
                            promise(.success(data))
                        }
                    } catch let error as NetworkError {
                        // Handle retries if an error occurs
                        var shouldRetry = false
                        for interceptor in self.retryInterceptors {
                            if try await interceptor.shouldRetry(localUrlRequest, dueTo: error) {
                                shouldRetry = true
                                break
                            }
                        }
                        if shouldRetry {
                            promise(.failure(NetworkError.retryNeeded)) // Use the retryNeeded case
                        } else {
                            promise(.failure(error))
                        }
                    }
                }
            }
        }
        .receive(on: receive) // Specify the dispatch queue
        .eraseToAnyPublisher() // Convert to AnyPublisher
    }
    
    public func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        receive: DispatchQueue
    ) async throws -> AnyPublisher<T, NetworkError> where T: Decodable {
        let urlRequest = try request.makeRequest()
        
        return Future<T, NetworkError> { promise in
            receive.async {
                Task {
                    do {
                        let (data, response) = try await self.session.data(for: urlRequest, delegate: self.delegate)
                        if let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse, responseData: data) {
                            promise(.failure(error))
                        } else {
                            do {
                                let decodedObject = try NetworkError.dataDecoding(codable: T.self, data: data)
                                promise(.success(decodedObject))
                            } catch let error as NetworkError {
                                promise(.failure(error))
                            }
                        }
                    } catch let error as NSError {
                        promise(.failure(NetworkError.convertErrorToNetworkError(error: error)))
                    }
                }
            }
        }
        .receive(on: receive) // Specify the dispatch queue
        .eraseToAnyPublisher() // Convert to AnyPublisher
    }
    
    public func serialRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) async throws -> [AnyPublisher<Data?, NetworkError>] {
        var publishers: [AnyPublisher<Data?, NetworkError>] = []
        
        for request in requests {
            let urlRequest: URLRequest
            
            do {
                urlRequest = try request.makeRequest()
            } catch {
                let publisher = Fail<Data?, NetworkError>(error: NetworkError.convertErrorToNetworkError(error: error as NSError))
                    .eraseToAnyPublisher()
                publishers.append(publisher)
                continue
            }
            
            let publisher: AnyPublisher<Data?, NetworkError> = Future<Data, NetworkError> { promise in
                receive.async {
                    Task {
                        do {
                            let (data, response) = try await self.session.data(for: urlRequest, delegate: self.delegate)
                            
                            if let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse, responseData: data) {
                                promise(.failure(error))
                            } else {
                                promise(.success(data))
                            }
                        } catch let error as NSError {
                            promise(.failure(NetworkError.convertErrorToNetworkError(error: error)))
                        }
                    }
                }
            }
                .map { $0 } // Convert Data to Data?
                .catch { error in
                    Just(nil) // Emit nil on error
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            
            publishers.append(publisher) // Append the publisher
        }
        
        return publishers // Return the array of publishers
    }
    
    public func serialRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        receive: DispatchQueue
    ) async throws -> [AnyPublisher<T, NetworkError>] where T: Decodable {
        
        var publishers: [AnyPublisher<T, NetworkError>] = []
        
        for request in requests {
            let urlRequest: URLRequest
            
            do {
                urlRequest = try request.makeRequest()
            } catch {
                let publisher = Fail<T, NetworkError>(error: NetworkError.convertErrorToNetworkError(error: error as NSError))
                    .eraseToAnyPublisher()
                publishers.append(publisher)
                continue
            }
            
            let publisher: AnyPublisher<T, NetworkError> = Future<T, NetworkError> { promise in
                receive.async {
                    Task {
                        do {
                            let (data, response) = try await self.session.data(for: urlRequest, delegate: self.delegate)
                            
                            // Validate the HTTP response
                            if let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse, responseData: data) {
                                promise(.failure(error))
                                return
                            }
                            
                            // Use your custom decoding method
                            do {
                                let decodedObject = try NetworkError.dataDecoding(codable: T.self, data: data)
                                receive.async {
                                    promise(.success(decodedObject))
                                }
                            } catch let error as NetworkError {
                                promise(.failure(error))
                            }
                            
                        } catch {
                            promise(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                        }
                    }
                }
            }
                .eraseToAnyPublisher()
            
            publishers.append(publisher) // Append the publisher
        }
        
        return publishers // Return the array of publishers
    }
    
    public func concurrentRequests(
        for requests: [NetworkRequestProtocol],
        receive: DispatchQueue
    ) async throws -> AnyPublisher<[Data?], NetworkError> {
        
        let publishers: [AnyPublisher<Data?, NetworkError>] = requests.map { request in
            let urlRequest: URLRequest
            
            do {
                urlRequest = try request.makeRequest()
            } catch {
                return Fail(error: NetworkError.convertErrorToNetworkError(error: error as NSError))
                    .eraseToAnyPublisher()
            }
            
            return Future<Data?, NetworkError> { promise in
                receive.async {
                    Task {
                        do {
                            let (data, response) = try await self.session.data(for: urlRequest, delegate: self.delegate)
                            
                            // Validate the HTTP response
                            if let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse, responseData: data) {
                                promise(.failure(error))
                            } else {
                                promise(.success(data))
                            }
                        } catch {
                            promise(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect() // Collect results into an array
            .eraseToAnyPublisher() // Return a publisher for the array of optional data
    }

    public func concurrentRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        receive: DispatchQueue
    ) async throws -> AnyPublisher<[T], NetworkError> where T: Decodable {
        
        let publishers: [AnyPublisher<T, NetworkError>] = requests.map { request in
            let urlRequest: URLRequest
            
            do {
                urlRequest = try request.makeRequest()
            } catch {
                return Fail<T, NetworkError>(error: NetworkError.convertErrorToNetworkError(error: error as NSError))
                    .eraseToAnyPublisher()
            }
            
            return Future<T, NetworkError> { promise in
                receive.async {
                    Task {
                        do {
                            let (data, response) = try await self.session.data(for: urlRequest, delegate: self.delegate)

                            // Validate the HTTP response
                            if let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse, responseData: data) {
                                promise(.failure(error))
                                return
                            }

                            // Use your custom decoding method
                            do {
                                let decodedObject = try NetworkError.dataDecoding(codable: T.self, data: data)
                                promise(.success(decodedObject))
                            } catch let error as NetworkError {
                                promise(.failure(error))
                            }

                        } catch {
                            promise(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect() // Collect results into an array
            .eraseToAnyPublisher() // Return a publisher for the array of decoded objects
    }
}
