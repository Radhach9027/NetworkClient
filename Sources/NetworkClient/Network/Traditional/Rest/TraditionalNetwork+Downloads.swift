import Foundation
import Network
import os.lock

@available(iOS 11.0, *)
public extension TraditionalNetwork {
    func download(
          for request: NetworkDownloadRequestProtocol,
          completion: @escaping (Result<NetworkDownloadResponse, NetworkError>) -> Void
    ) {
        guard Self.isInternetReachable else {
            completion(.failure(.noInternet))
            return
        }
        
        let requestStartTime = Date()
        do {
            var urlRequest = try request.makeRequest()
            guard applyRequestInterceptors(&urlRequest) else {
                completion(.failure(.requestInterceptionFailed))
                return
            }
            
            let task = session.downloadTask(with: urlRequest) { [weak self] url, response, error in
                let requestEndTime = Date()
                
                if let error = error {
                    self?.handleDownloadError(
                        error: error,
                        request: request,
                        completion: completion
                    )
                    return
                }
                
                guard let url = url else {
                    completion(.failure(.badUrl))
                    return
                }
                
                let loggerString = self?.logToConsole(
                    request: urlRequest,
                    response: response!,
                    requestStartTime: requestStartTime,
                    responseTime: requestEndTime,
                    responseData: nil
                ) ?? ""
                
                if let savedToLocation = request.saveDownloadedUrlToLocation {
                    self?.saveUrlToFileManagerIfExists(
                        savedToLocation: savedToLocation,
                        urlToBeSaved: url,
                        loggerString: loggerString,
                        endPoint: request,
                        completion: completion
                    )
                } else {
                    completion(.success(.response(
                        data: url,
                        loggerString: loggerString,
                        endPoint: request
                    )))
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
                    completion(.failure(.downloadSuspended))
                case .canceling:
                    completion(.failure(.downloadCancelled))
                case .completed:
                    progressObservation.invalidate()
                @unknown default:
                    completion(.failure(.unknown))
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(.unknown))
            return
        }
    }

    func downloadSerialRequests(
        for requests: [NetworkDownloadRequestProtocol],
        individualCompletion: @escaping (Result<NetworkDownloadResponse, NetworkError>, Int) -> Void,
        finalCompletion: @escaping () -> Void
    ) {
        guard Self.isInternetReachable else {
            for index in requests.indices {
                individualCompletion(.failure(.noInternet), index)
            }
            finalCompletion()
            return
        }

        var currentIndex = 0

        func handleNextRequest() {
            if currentIndex >= requests.count {
                finalCompletion()
                return
            }

            let request = requests[currentIndex]
            download(for: request) { result in
                individualCompletion(result, currentIndex)
                currentIndex += 1
                handleNextRequest()
            }
        }

        handleNextRequest()
    }

    func downloadConcurrentRequests(
        for requests: [NetworkDownloadRequestProtocol],
        completion: @escaping (Result<[NetworkDownloadResponse], NetworkError>) -> Void
    ) {
        guard Self.isInternetReachable else {
            completion(.failure(.noInternet))
            return
        }

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount

        var unfairLock = os_unfair_lock_s()
        var results: [NetworkDownloadResponse?] = Array(repeating: nil, count: requests.count)
        var errors: [NetworkError] = []

        let completionOperation = BlockOperation {
            if !errors.isEmpty {
                completion(.failure(errors.first!))
            } else {
                completion(.success(results.compactMap { $0 }))
            }
        }

        for (index, request) in requests.enumerated() {
            let requestOperation = BlockOperation {
                self.download(for: request) { result in
                    os_unfair_lock_lock(&unfairLock)
                    defer { os_unfair_lock_unlock(&unfairLock) }

                    switch result {
                    case let .success(response):
                        results[index] = response
                    case let .failure(error):
                        errors.append(error)
                    }
                }
            }

            completionOperation.addDependency(requestOperation)
            operationQueue.addOperation(requestOperation)
        }

        operationQueue.addOperation(completionOperation)
    }
}

private extension TraditionalNetwork {
    
    func handleDownloadError(
         error: Error,
         request: NetworkDownloadRequestProtocol,
         completion: @escaping (Result<NetworkDownloadResponse, NetworkError>) -> Void
     ) {
         let networkError = NetworkError.convertErrorToNetworkError(error: error as NSError)
         retryDownloadRequest(
             request: request,
             error: networkError,
             completion: completion
         )
     }
    
    func retryDownloadRequest(
        request: NetworkDownloadRequestProtocol,
        error: NetworkError,
        completion: @escaping (Result<NetworkDownloadResponse, NetworkError>) -> Void
    ) {
        guard !retryInterceptors.isEmpty else {
            completion(.failure(.retryInterceptionFailed))
            return
        }

        let bumpedRequest = RetriableRequest(base: request)
        for interceptor in retryInterceptors {
            interceptor.shouldRetry(bumpedRequest, dueTo: error) { result in
                switch result {
                case .success(.retry):
                    self.download(for: bumpedRequest, completion: completion)
                case let .success(.retryWithDelay(delay)):
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.download(for: bumpedRequest, completion: completion)
                    }
                case .success(.noRetry):
                    completion(.failure(error))
                case let .failure(retryError):
                    completion(.failure(retryError))
                }
            }
            return
        }

        completion(.failure(error))
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
}

private extension TraditionalNetwork {
    
    func saveUrlToFileManagerIfExists(
        savedToLocation: URL,
        urlToBeSaved: URL,
        loggerString: String,
        endPoint: NetworkDownloadRequestProtocol?,
        completion: @escaping (Result<NetworkDownloadResponse, NetworkError>) -> Void
    ) {
        let fileManager = FileManager.default
        let folder = savedToLocation.deletingLastPathComponent()

        // Create parent directory if needed
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        // Remove existing file if it already exists
        if fileManager.fileExists(atPath: savedToLocation.path) {
            do {
                try fileManager.removeItem(at: savedToLocation)
                print("⚠️ Removed existing file at: \(savedToLocation.path)")
            } catch {
                print("❌ Failed to remove existing file: \(error.localizedDescription)")
            }
        }

        // Move the downloaded file
        do {
            try fileManager.moveItem(at: urlToBeSaved, to: savedToLocation)
            print("✅ Moved file to: \(savedToLocation.path)")
            completion(.success(.response(
                data: savedToLocation,
                loggerString: loggerString,
                endPoint: endPoint
            )))
        } catch {
            print("❌ Failed to move file to \(savedToLocation.path): \(error.localizedDescription)")
            completion(.failure(.saveUrlToFileManager(error.localizedDescription)))
        }
    }
}

