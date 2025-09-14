import Foundation
import os.lock

@available(iOS 11.0, *)
public extension TraditionalNetwork {
    func request(
        for request: NetworkRequestProtocol,
        completion: @escaping (Result<NetworkSuccessResult<Data>, NetworkError>) -> Void
    ) {
        guard Self.isInternetReachable else {
            completion(.failure(.noInternet))
            return
        }
        
        let identifier = getRequestIdentifier(from: request)
        let operationQueue = RequestQueueManager.shared.getQueue(for: identifier)
        let operation = BlockOperation {
            self.handleRequest(request: request) { result in
                completion(result)
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        completion: @escaping (Result<NetworkSuccessResult<T>, NetworkError>) -> Void
    ) where T: Decodable {
        guard Self.isInternetReachable else {
            completion(.failure(.noInternet))
            return
        }
        
        let identifier = getRequestIdentifier(from: request)
        let operationQueue = RequestQueueManager.shared.getQueue(for: identifier)
        let operation = BlockOperation {
            self.handleRequest(request: request) { result in
                switch result {
                case let .success(data):
                    switch data {
                    case let .success(data, loggerString):
                        do {
                            let decodedObject = try NetworkError.dataDecoding(codable: T.self, data: data)
                            completion(.success(.success(data: decodedObject, loggerString: loggerString)))
                        } catch let error as NetworkError {
                            completion(.failure(error))
                        } catch {
                            completion(.failure(.unknown))
                        }
                    }
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func serialRequests(
        for requests: [NetworkRequestProtocol],
        completion: @escaping (Result<[NetworkSuccessResult<Data>?], NetworkError>) -> Void
    ) {
        if Self.isInternetReachable {
            var results: [NetworkSuccessResult<Data>?] = []
            var currentIndex = 0
            var firstError: NetworkError?
            
            func handleNextRequest() {
                if currentIndex >= requests.count {
                    if let error = firstError {
                        completion(.failure(error))
                    } else {
                        completion(.success(results))
                    }
                    return
                }
                
                let request = requests[currentIndex]
                
                handleRequest(request: request) { result in
                    switch result {
                    case let .success(data):
                        results.append(data)
                        currentIndex += 1
                        handleNextRequest()
                    case let .failure(error):
                        if firstError == nil {
                            firstError = error
                        }
                        currentIndex += 1
                        handleNextRequest()
                    }
                }
            }
            
            handleNextRequest()
        } else {
            completion(.failure(.noInternet))
        }
    }
    
    func serialRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        completion: @escaping (Result<[NetworkSuccessResult<T>], NetworkError>) -> Void
    ) where T: Decodable {
        if Self.isInternetReachable {
            var results: [NetworkSuccessResult<T>] = []
            var currentIndex = 0
            var firstError: NetworkError?
            
            func handleNextRequest() {
                if currentIndex >= requests.count {
                    if let error = firstError {
                        completion(.failure(error))
                    } else {
                        completion(.success(results))
                    }
                    return
                }
                
                let request = requests[currentIndex]
                
                handleRequest(request: request) { result in
                    switch result {
                    case let .success(data):
                        switch data {
                        case let .success(data, loggerString):
                            do {
                                let decodedObject = try NetworkError.dataDecoding(codable: T.self, data: data)
                                results.append(.success(data: decodedObject, loggerString: loggerString))
                            } catch let error as NetworkError {
                                if firstError == nil {
                                    firstError = error
                                }
                            } catch {
                                if firstError == nil {
                                    firstError = .unknown
                                }
                            }
                            currentIndex += 1
                            handleNextRequest()
                            
                        }
                    case let .failure(error):
                        if firstError == nil {
                            firstError = error
                        }
                        currentIndex += 1
                        handleNextRequest()
                    }
                }
            }
            
            handleNextRequest()
        } else {
            completion(.failure(.noInternet))
        }
    }
    
    func concurrentRequests(
        for requests: [NetworkRequestProtocol],
        individualCompletion: @escaping (Result<NetworkSuccessResult<Data>?, NetworkError>) -> Void,
        finalCompletion: @escaping (Result<[NetworkSuccessResult<Data>?], NetworkError>) -> Void
    ) {
        guard Self.isInternetReachable else {
            finalCompletion(.failure(.noInternet))
            return
        }
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        
        var unfairLock = os_unfair_lock_s()
        var results: [NetworkSuccessResult<Data>?] = Array(repeating: nil, count: requests.count)
        var errors: [NetworkError] = []
        
        let completionOperation = BlockOperation {
            if !errors.isEmpty {
                finalCompletion(.failure(errors.first!))
            } else {
                finalCompletion(.success(results))
            }
        }
        
        for (index, request) in requests.enumerated() {
            let requestOperation = BlockOperation {
                self.handleRequest(request: request) { result in
                    os_unfair_lock_lock(&unfairLock)
                    defer { os_unfair_lock_unlock(&unfairLock) }
                    
                    switch result {
                    case let .success(data):
                        results[index] = data
                        individualCompletion(.success(data))
                    case let .failure(error):
                        errors.append(error)
                        individualCompletion(.failure(error))
                    }
                }
            }
            
            completionOperation.addDependency(requestOperation)
            operationQueue.addOperation(requestOperation)
        }
        
        operationQueue.addOperation(completionOperation)
    }
    
    func concurrentRequests<T>(
        for requests: [NetworkRequestProtocol],
        codable: T.Type,
        individualCompletion: @escaping (Result<NetworkSuccessResult<T>, NetworkError>) -> Void,
        finalCompletion: @escaping (Result<[NetworkSuccessResult<T>], NetworkError>) -> Void
    ) where T: Decodable {
        guard Self.isInternetReachable else {
            finalCompletion(.failure(.noInternet))
            return
        }
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        
        var unfairLock = os_unfair_lock_s()
        var results: [NetworkSuccessResult<T>?] = Array(repeating: nil, count: requests.count)
        var errors: [NetworkError] = []
        
        let completionOperation = BlockOperation {
            if !errors.isEmpty {
                finalCompletion(.failure(errors.first!))
            } else {
                let decodedResults = results.compactMap { $0 }
                finalCompletion(.success(decodedResults))
            }
        }
        
        for (index, request) in requests.enumerated() {
            let requestOperation = BlockOperation {
                self.handleRequest(request: request) { result in
                    switch result {
                    case let .success(data):
                        switch data {
                        case let .success(data, loggerString):
                            do {
                                let decodedObject = try NetworkError.dataDecoding(codable: T.self, data: data)
                                os_unfair_lock_lock(&unfairLock)
                                results[index] = .success(data: decodedObject, loggerString: loggerString)
                                os_unfair_lock_unlock(&unfairLock)
                                individualCompletion(.success(.success(data: decodedObject, loggerString: loggerString)))
                            } catch let error as NetworkError {
                                os_unfair_lock_lock(&unfairLock)
                                errors.append(error)
                                os_unfair_lock_unlock(&unfairLock)
                                individualCompletion(.failure(error))
                            } catch {
                                os_unfair_lock_lock(&unfairLock)
                                errors.append(.unknown)
                                os_unfair_lock_unlock(&unfairLock)
                                individualCompletion(.failure(.unknown))
                            }
                        }
                    case let .failure(error):
                        os_unfair_lock_lock(&unfairLock)
                        errors.append(error)
                        os_unfair_lock_unlock(&unfairLock)
                        individualCompletion(.failure(error))
                    }
                }
            }
            
            completionOperation.addDependency(requestOperation)
            operationQueue.addOperation(requestOperation)
        }
        
        operationQueue.addOperation(completionOperation)
    }
    
    func logError(_ error: NetworkError, url: URL?) {
        if let logger = logger,
           let url = url {
            logger.logRequest(
                url: url,
                error: error,
                type: .error,
                privacy: .encrypt
            )
        }
    }
}

@available(iOS 11.0, *)
private extension TraditionalNetwork {
    func handleRequest(
        request: NetworkRequestProtocol,
        completion: @escaping (Result<NetworkSuccessResult<Data>, NetworkError>) -> Void
    ) {
        do {
            let requestStartTime = Date()
            var urlRequest = try request.makeRequest()
            
            guard applyRequestInterceptors(&urlRequest, request) else {
                completion(.failure(.requestInterceptionFailed))
                return
            }
            
            // 🔎 Try serving from cache
            if let cachedResult = checkValidCache(
                for: request,
                urlRequest: &urlRequest,
                requestStartTime: requestStartTime
            ) {
                completion(.success(cachedResult))
                return
            }
            
            // 🌐 Perform actual request
            session.dataTask(with: urlRequest) { [weak self] data, response, error in
                let requestEndTime = Date()
                
                var loggerString = ""
                if let response = response {
                    loggerString = self?.logToConsole(
                        request: urlRequest,
                        response: response,
                        requestStartTime: requestStartTime,
                        responseTime: requestEndTime,
                        responseData: data
                    ) ?? ""
                }
                
                if let error = error {
                    self?.handleError(
                        error: error,
                        data: data,
                        request: request,
                        completion: completion
                    )
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknown))
                    return
                }
                
                if let validationError = NetworkError.validateHTTPError(
                    urlResponse: httpResponse,
                    responseData: data
                ) {
                    self?.handleNetworkError(validationError, request: request, completion: completion)
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.unknown))
                    return
                }
                
                // 💾 Cache if needed
                self?.storeResponseInCacheIfNeeded(
                    request: request,
                    urlRequest: &urlRequest,
                    data: data,
                    response: httpResponse
                )
                                
                completion(.success(.success(data: data, loggerString: loggerString)))
            }.resume()
            
        } catch {
            completion(.failure(.unknown))
        }
    }
    
    func applyRequestInterceptors(_ request: inout URLRequest, _ logicalRequest: NetworkRequestProtocol) -> Bool {
        let chain = requestInterceptors.filter { logicalRequest.allowedRequestInterceptorIDs?.contains($0.id) ?? false }
        guard !chain.isEmpty else { return true }

        for interceptor in chain {
            switch interceptor.adapt(&request) {
            case .success: continue
            case .failure(let error):
                logError(error, url: request.url)
                return false
            }
        }
        return true
    }
    
    func retryRequest(
        request: NetworkRequestProtocol,
        error: NetworkError,
        completion: @escaping (Result<NetworkSuccessResult<Data>, NetworkError>) -> Void
    ) {
        let chain = retryInterceptors.filter { request.allowedRequestInterceptorIDs?.contains($0.id) ?? false }
        guard !chain.isEmpty else {
            completion(.failure(.retryInterceptionFailed))
            return
        }

        let bumpedRequest = bumpRetry(request)

        func runChain(_ index: Int) {
            guard index < chain.count else {
                completion(.failure(error))
                return
            }

            let interceptor = chain[index]
            interceptor.shouldRetry(bumpedRequest, dueTo: error) { result in
                switch result {
                case .success(.retry):
                    self.handleRequest(request: bumpedRequest, completion: completion)

                case .success(.retryWithDelay(let delay)):
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self else { completion(.failure(error)); return }
                        self.handleRequest(request: bumpedRequest, completion: completion)
                    }

                case .success(.noRetry):
                    runChain(index + 1)
                case .failure(let retryError):
                    self.logError(retryError, url: request.urlComponents?.url?.baseURL)
                    completion(.failure(retryError))
                }
            }
        }

        runChain(0)
    }

    func bumpRetry(_ request: NetworkRequestProtocol) -> NetworkRequestProtocol {
        RetriableRequest(base: request)
    }
    
    func handleError(
        error: Error?,
        response: HTTPURLResponse? = nil,
        data: Data? = nil,
        request: NetworkRequestProtocol,
        completion: @escaping (Result<NetworkSuccessResult<Data>, NetworkError>) -> Void
    ) {
        if let error = error {
            let networkError = NetworkError.convertErrorToNetworkError(error: error as NSError)
            retryRequest(
                request: request,
                error: networkError,
                completion: completion
            )
            return
        }
        
        if let httpResponse = response,
           let validationError = NetworkError.validateHTTPError(
            urlResponse: httpResponse,
            responseData: data) {
            retryRequest(
                request: request,
                error: validationError,
                completion: completion
            )
            return
        }
    }
    
    func handleNetworkError(
        _ networkError: NetworkError,
        request: NetworkRequestProtocol,
        completion: @escaping (Result<NetworkSuccessResult<Data>, NetworkError>) -> Void
    ) {
        if networkError == .retryNeeded
            || networkError == .refreshTokenExpired
            || networkError == .tokenRevoked {
            retryRequest(
                request: request,
                error: networkError,
                completion: completion
            )
        } else {
            logError(
                networkError,
                url: request.urlComponents?.url?.baseURL
            )
            completion(.failure(networkError))
        }
    }

    func getRequestIdentifier(from request: NetworkRequestProtocol) -> String {
        if let path = request.urlComponents?.path, !path.isEmpty {
            return path.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let urlString = request.urlComponents?.url?.absoluteString, !urlString.isEmpty {
            return urlString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "defaultIdentifier"
    }
    
    func checkValidCache(
        for request: NetworkRequestProtocol,
        urlRequest: inout URLRequest,
        requestStartTime: Date
    ) -> NetworkSuccessResult<Data>? {
        guard let cachePolicyInGMT = request.cachePolicy,
              let cachedResponse = URLCache.shared.cachedResponse(for: urlRequest) else {
            return nil
        }
        
        if cachePolicyInGMT.isCacheValid {
            let loggerString = logToConsole(
                request: urlRequest,
                response: cachedResponse.response,
                requestStartTime: requestStartTime,
                responseTime: Date(),
                responseData: cachedResponse.data,
                isFromCache: true
            )
            return .success(
                data: cachedResponse.data,
                loggerString: loggerString
            )
        } else {
            urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            URLCache.shared.removeCachedResponse(for: urlRequest)
            return nil
        }
    }
    
    func storeResponseInCacheIfNeeded(
        request: NetworkRequestProtocol,
        urlRequest: inout URLRequest,
        data: Data,
        response: HTTPURLResponse
    ) {
        guard let cachePolicyInGMT = request.cachePolicy,
              cachePolicyInGMT.isCacheValid else {
            urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            URLCache.shared.removeCachedResponse(for: urlRequest)
            return
        }
        
        let cachedResponse = CachedURLResponse(
            response: response,
            data: data,
            userInfo: nil,
            storagePolicy: .allowed
        )
        
        urlRequest.cachePolicy = .useProtocolCachePolicy
        URLCache.shared.storeCachedResponse(cachedResponse, for: urlRequest)
    }
}
