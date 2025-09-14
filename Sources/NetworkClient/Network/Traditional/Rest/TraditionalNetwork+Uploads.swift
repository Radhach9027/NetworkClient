import Foundation
import Network

@available(iOS 11.0, *)
public extension TraditionalNetwork {
    func upload(
        with request: NetworkUploadRequestProtocol,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    ) {
        guard Self.isInternetReachable else {
            completion(.failure(.noInternet))
            return
        }

        let identifier = getRequestIdentifier(from: request)
        let operationQueue = RequestQueueManager.shared.getQueue(for: identifier)
        var lock = os_unfair_lock_s()

        let operation = BlockOperation {
            os_unfair_lock_lock(&lock)
            do {
                var urlRequest = try request.makeRequest()
                guard self.applyRequestInterceptors(&urlRequest) else {
                    completion(.failure(.requestInterceptionFailed))
                    return
                }

                switch request.uploadFile {
                case let .url(fileURL):
                    self.uploadFile(
                        from: fileURL,
                        request: urlRequest,
                        completion: completion
                    )

                case let .data(data):
                    self.uploadData(
                        data: data,
                        request: urlRequest,
                        completion: completion
                    )
                }
            } catch {
                completion(.failure(.badRequestConstructed))
            }
            os_unfair_lock_unlock(&lock)
        }

        operationQueue.addOperation(operation)
    }

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    ) {
        do {
            let requestStartTime = Date()
            let urlRequest = try request.makeRequest()
            let formData = request.makeFormBody()

            let uploadTask = session.uploadTask(
                with: urlRequest,
                from: formData
            ) { [weak self] data, response, error in
                if let error = error {
                    self?.handleNetworkError(
                        error: error,
                        response: response as? HTTPURLResponse,
                        request: request as! NetworkUploadRequestProtocol,
                        completion: completion
                    )
                    return
                }

                guard let data = data else {
                    completion(.failure(.unknown))
                    return
                }

                let requestEndTime = Date()
                let loggerString = self?.logToConsole(
                    request: urlRequest,
                    response: response!,
                    requestStartTime: requestStartTime,
                    responseTime: requestEndTime,
                    responseData: nil
                ) ?? ""
                completion(.success(.response(data: data, loggerString: loggerString)))
            }

            uploadTask.resume()
        } catch {
            completion(.failure(.badRequestConstructed))
        }
    }

    func serialUpload(
        with requests: [NetworkUploadRequestProtocol],
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    ) {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        var lock = os_unfair_lock_s()

        for request in requests {
            let operation = BlockOperation {
                os_unfair_lock_lock(&lock)
                do {
                    let urlRequest = try request.makeRequest()
                    switch request.uploadFile {
                    case let .url(fileURL):
                        self.uploadFile(
                            from: fileURL,
                            request: urlRequest,
                            completion: completion
                        )
                    case let .data(data):
                        self.uploadData(
                            data: data,
                            request: urlRequest,
                            completion: completion
                        )
                    }

                } catch {
                    completion(.failure(.badRequestConstructed))
                }
                os_unfair_lock_unlock(&lock)
            }

            operationQueue.addOperation(operation)
        }
    }

    func concurrentUpload(
        with requests: [NetworkUploadRequestProtocol],
        completion: @escaping (Result<[NetworkUploadResponse], NetworkError>) -> Void
    ) {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount

        var lock = os_unfair_lock_s()
        var responses = [NetworkUploadResponse]()
        var pendingOperations = requests.count

        let completionBlock: (Result<NetworkUploadResponse, NetworkError>) -> Void = { result in
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }

            switch result {
            case let .success(response):
                responses.append(response)
            case let .failure(error):
                completion(.failure(error))
                return
            }

            pendingOperations -= 1
            if pendingOperations == 0 {
                completion(.success(responses))
            }
        }

        for request in requests {
            let operation = BlockOperation {
                os_unfair_lock_lock(&lock)
                do {
                    let urlRequest = try request.makeRequest()
                    switch request.uploadFile {
                    case let .url(fileURL):
                        self.uploadFile(
                            from: fileURL,
                            request: urlRequest,
                            completion: completionBlock
                        )

                    case let .data(data):
                        self.uploadData(
                            data: data,
                            request: urlRequest,
                            completion: completionBlock
                        )
                    }

                } catch {
                    completion(.failure(.badRequestConstructed))
                    return
                }
                os_unfair_lock_unlock(&lock)
            }

            operationQueue.addOperation(operation)
        }
    }
}

private extension TraditionalNetwork {
    func uploadFile(
        from fileURL: URL,
        request: URLRequest,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    ) {
        let requestStartTime = Date()
        let task = session.uploadTask(
            with: request,
            fromFile: fileURL
        ) { [weak self] data, response, error in
            if let error = error {
                self?.handleNetworkError(
                    error: error,
                    response: response as? HTTPURLResponse,
                    request: request as! NetworkUploadRequestProtocol,
                    completion: completion
                )
                return
            }

            guard let data = data else {
                completion(.failure(.unknown))
                return
            }

            let requestEndTime = Date()
            let loggerString = self?.logToConsole(
                request: request,
                response: response!,
                requestStartTime: requestStartTime,
                responseTime: requestEndTime,
                responseData: nil
            ) ?? ""
            completion(.success(.response(data: data, loggerString: loggerString)))
        }

        let progressObservation = task.progress.observe(\.fractionCompleted) { progress, _ in
            let percentage = Float(progress.fractionCompleted)
            completion(.success(.progress(percentage: percentage)))
        }

        _ = task.observe(\.state, options: [.new]) { task, _ in
            switch task.state {
            case .running:
                break
            case .suspended:
                completion(.failure(.uploadSuspended))
            case .canceling:
                completion(.failure(.uploadCancelled))
            case .completed:
                progressObservation.invalidate()
            @unknown default:
                completion(.failure(.unknown))
            }
        }
        task.resume()
    }


    func uploadData(
        data: Data,
        request: URLRequest,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    ) {
        let requestStartTime = Date()
        let task = session.uploadTask(with: request, from: data) { [weak self] responseData, response, error in
            if let error = error {
                completion(.failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
            } else if let responseData = responseData {
                let requestEndTime = Date()
                let loggerString = self?.logToConsole(
                    request: request,
                    response: response!,
                    requestStartTime: requestStartTime,
                    responseTime: requestEndTime,
                    responseData: nil
                ) ?? ""
                completion(.success(.response(data: responseData, loggerString: loggerString)))
            } else {
                completion(.failure(.unknown))
            }
        }

        let progressObservation = task.progress.observe(\.fractionCompleted) { progress, _ in
            let percentage = Float(progress.fractionCompleted)
            completion(.success(.progress(percentage: percentage)))
        }

        _ = task.observe(\.state, options: [.new]) { task, _ in
            switch task.state {
            case .running:
                break
            case .suspended:
                completion(.failure(.uploadSuspended))
            case .canceling:
                completion(.failure(.uploadCancelled))
            case .completed:
                progressObservation.invalidate()
            @unknown default:
                completion(.failure(.unknown))
            }
        }

        task.resume()
    }

    func retryRequest(
        request: NetworkUploadRequestProtocol,
        error: NetworkError,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
    ) {
        guard !retryInterceptors.isEmpty else {
            completion(.failure(.retryInterceptionFailed))
            return
        }
        
        for interceptor in retryInterceptors {
            interceptor.shouldRetry(request, dueTo: error) { result in
                switch result {
                case .success(.retry):
                    self.upload(with: request, completion: completion)
                    
                case let .success(.retryWithDelay(delay)):
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else {
                            completion(.failure(error))
                            return
                        }
                        self.upload(with: request, completion: completion)
                    }
                    
                case .success(.noRetry):
                    completion(.failure(error))
                    
                case let .failure(retryError):
                    self.logError(retryError, url: request.urlComponents?.url?.baseURL)
                    completion(.failure(retryError))
                }
            }
            return
        }
        completion(.failure(error))
    }

    func handleNetworkError(
        error: Error?,
        response: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        request: NetworkUploadRequestProtocol,
        completion: @escaping (Result<NetworkUploadResponse, NetworkError>) -> Void
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
           let validationError = NetworkError.validateHTTPError(urlResponse: httpResponse, responseData: responseData) {
            retryRequest(
                request: request,
                error: validationError,
                completion: completion
            )
            return
        }
    }

    func applyRequestInterceptors(_ request: inout URLRequest) -> Bool {
        guard !requestInterceptors.isEmpty else {
            return true
        }
        for interceptor in requestInterceptors {
            let result = interceptor.adapt(&request)
            switch result {
            case .success:
                continue
            case let .failure(error):
                logError(error, url: request.url)
                return false
            }
        }
        return true
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
}
