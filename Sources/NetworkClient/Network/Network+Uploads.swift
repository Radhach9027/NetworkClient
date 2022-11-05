import Combine
import Foundation

// MARK: Upload Tasks

public extension Network {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<UploadNetworkResponse, NetworkError> {
        do {
            let uploadRequest = try request.makeRequest()
            delegate.requestType = .upload
            switch request.uploadFile {
            case let .data(data):
                session.uploadTask(
                    with: uploadRequest,
                    from: data
                ).resumeTask()
            case let .url(url):
                session.uploadTask(
                    with: uploadRequest,
                    fromFile: url
                ).resumeTask()
            }
            return delegate.uploadProgressSubject

        } catch let error as NSError {
            let failure = PassthroughSubject<UploadNetworkResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<UploadNetworkResponse, NetworkError> {
        do {
            let multipartRequest = try request.makeRequest()
            delegate.requestType = .upload
            session.uploadTask(with: multipartRequest, from: request.makeFormBody()).resumeTask()
            return delegate.uploadProgressSubject
        } catch let error as NSError {
            let failure = PassthroughSubject<UploadNetworkResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
}
