import Combine
import Foundation

// MARK: Download Tasks
extension Network {
    public func download(
        for request: NetworkDownloadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<DownloadNetworkResponse, NetworkError> {
        do {
            let downloadRequest = try request.makeRequest()
            delegate.requestType = .download
            delegate.saveToLocation = request.saveDownloadedUrlToLocation
            session.downloadTask(with: downloadRequest).resumeTask()
            return delegate.downloadProgressSubject
        } catch let error as NSError {
            let failure = PassthroughSubject<DownloadNetworkResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
}
