import Combine
import Foundation

// MARK: Upload Tasks

@available(iOS 13.0, *)
public extension CombineNetwork {
    func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkUploadResponse, NetworkError> {
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
            let failure = PassthroughSubject<NetworkUploadResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }

    func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) -> PassthroughSubject<NetworkUploadResponse, NetworkError> {
        do {
            let multipartRequest = try request.makeRequest()
            delegate.requestType = .upload
            session.uploadTask(with: multipartRequest, from: request.makeFormBody()).resumeTask()
            return delegate.uploadProgressSubject
        } catch let error as NSError {
            let failure = PassthroughSubject<NetworkUploadResponse, NetworkError>()
            failure.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
            return failure
        }
    }
    
    func concurrentUpload(
        with requests: [NetworkUploadRequestProtocol],
        receive: DispatchQueue
    ) -> AnyPublisher<[NetworkUploadResponse], NetworkError> {
        
        // Create an array of publishers for each upload request
        let publishers: [AnyPublisher<NetworkUploadResponse, NetworkError>] = requests.map { request in
            return self.upload(with: request, receive: receive)
                .eraseToAnyPublisher() // Convert to AnyPublisher
        }
        
        // Use Publishers.Merge to combine all publishers and collect results
        return Publishers.MergeMany(publishers)
            .collect() // Collect results into an array
            .eraseToAnyPublisher() // Return a publisher for the array of responses
    }
}
