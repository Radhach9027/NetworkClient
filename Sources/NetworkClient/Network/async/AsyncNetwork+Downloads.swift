import Combine
import Foundation

@available(iOS 15.0, *)
extension AsyncNetwork {
    // MARK: Serial Download
    public func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkDownloadResponse, NetworkError> {
        let subject = PassthroughSubject<NetworkDownloadResponse, NetworkError>()
        
        do {
            // Attempt to create the download request
            let downloadRequest = try request.makeRequest()
            let downloadTask = session.downloadTask(with: downloadRequest) { [weak subject] location, response, error in
                self.handleDownloadCompletion(location: location, response: response, error: error, subject: subject)
            }
            
            self.trackDownloadProgress(for: downloadTask, subject: subject)
            downloadTask.resume()
            
        } catch {
            subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
        }
        
        return subject
    }
    
    // MARK: Concurrent Downloads
    public func downloadConcurrent(
        for requests: [NetworkDownloadRequestProtocol],
        receive: DispatchQueue
    ) async throws -> [PassthroughSubject<NetworkDownloadResponse, NetworkError>] {
        var subjects: [PassthroughSubject<NetworkDownloadResponse, NetworkError>] = []
        
        await withTaskGroup(of: Void.self) { group in
            for request in requests {
                let subject = PassthroughSubject<NetworkDownloadResponse, NetworkError>()
                subjects.append(subject)
                
                group.addTask {
                    // Since `makeRequest` might throw, we handle it within this task
                    do {
                        let downloadRequest = try request.makeRequest()
                        let downloadTask = self.session.downloadTask(with: downloadRequest) { [weak subject] location, response, error in
                            self.handleDownloadCompletion(location: location, response: response, error: error, subject: subject)
                        }
                        
                        self.trackDownloadProgress(for: downloadTask, subject: subject)
                        downloadTask.resume()
                    } catch {
                        // Handle errors related to making the request
                        subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                    }
                }
            }
        }
        
        return subjects
    }
    
    // MARK: Batch Downloads
    public func downloadBatch(
        for requests: [NetworkDownloadRequestProtocol],
        receive: DispatchQueue
    ) async throws -> [PassthroughSubject<NetworkDownloadResponse, NetworkError>] {
        var subjects: [PassthroughSubject<NetworkDownloadResponse, NetworkError>] = []

        for request in requests {
            let subject = PassthroughSubject<NetworkDownloadResponse, NetworkError>()
            subjects.append(subject)

            do {
                let downloadRequest = try request.makeRequest()
                
                await withCheckedContinuation { continuation in
                    let downloadTask = session.downloadTask(with: downloadRequest) { [weak subject] location, response, error in
                        self.handleDownloadCompletion(location: location, response: response, error: error, subject: subject)
                        continuation.resume() // Resume the continuation once the task is complete
                    }

                    self.trackDownloadProgress(for: downloadTask, subject: subject)
                    downloadTask.resume()
                }
            } catch {
                subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
            }
        }
        
        return subjects
    }
}

@available(iOS 15.0, *)
private extension AsyncNetwork {
    
    // MARK: Private Helper Methods
    func handleDownloadCompletion(location: URL?, response: URLResponse?, error: Error?, subject: PassthroughSubject<NetworkDownloadResponse, NetworkError>?) {
        if let error = error {
            subject?.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
            return
        }
        
        guard let location = location else {
            subject?.send(completion: .failure(NetworkError.unknown))
            return
        }
        
        let destinationURL = self.getDestinationURL(response: response)
        self.moveDownloadedFile(from: location, to: destinationURL, subject: subject)
    }
    
    func getDestinationURL(response: URLResponse?) -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(response?.suggestedFilename ?? "downloadedFile")
    }
    
    func moveDownloadedFile(from location: URL, to destinationURL: URL, subject: PassthroughSubject<NetworkDownloadResponse, NetworkError>?) {
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            subject?.send(.response(data: destinationURL))
            subject?.send(completion: .finished)
        } catch {
            subject?.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
        }
    }
    
    func trackDownloadProgress(for task: URLSessionDownloadTask, subject: PassthroughSubject<NetworkDownloadResponse, NetworkError>) {
        _ = (task.progress as Progress).observe(\.fractionCompleted) { progress, _ in
            let percentage = Float(progress.fractionCompleted) * 100
            subject.send(.progress(percentage: percentage))
        }
    }
}
