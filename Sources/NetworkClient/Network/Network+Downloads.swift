import Combine
import Foundation

// MARK: Download Tasks

public extension Network {
    func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkDownloadResponse, NetworkError> {
        do {
            let downloadRequest = try request.makeRequest()
            delegate.requestType = .download
            delegate.saveToLocation = request.saveDownloadedUrlToLocation
            session.downloadTask(with: downloadRequest).resumeTask()
            return delegate.downloadProgressSubject
        } catch let error as NSError {
            let failure = PassthroughSubject<NetworkDownloadResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
}
