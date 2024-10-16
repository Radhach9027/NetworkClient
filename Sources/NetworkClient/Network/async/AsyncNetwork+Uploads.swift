import Combine
import Foundation

@available(iOS 15.0, *)
extension AsyncNetwork {
    public func uploadSerial(
          with requests: [NetworkUploadRequestProtocol],
          receive: DispatchQueue
      ) async throws -> [PassthroughSubject<NetworkUploadResponse, NetworkError>] {
          var subjects: [PassthroughSubject<NetworkUploadResponse, NetworkError>] = []

          for request in requests {
              let subject = PassthroughSubject<NetworkUploadResponse, NetworkError>()
              subjects.append(subject)

              // Use the upload queue for serial execution
              receive.async {
                  Task {
                      do {
                          let uploadRequest = try request.makeRequest()

                          switch request.uploadFile {
                          case let .data(data):
                              try await self.performUpload(subject: subject, request: uploadRequest, data: data)

                          case let .url(url):
                              try await self.performUpload(subject: subject, request: uploadRequest, url: url)
                          }
                      } catch {
                          subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
                      }
                  }
              }
          }

          return subjects
      }

    
    public func upload(
        with request: NetworkUploadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkUploadResponse, NetworkError> {
        let subject = PassthroughSubject<NetworkUploadResponse, NetworkError>()
        
        do {
            let uploadRequest = try request.makeRequest()
            switch request.uploadFile {
            case let .data(data):
                try await performUpload(subject: subject, request: uploadRequest, data: data)
                
            case let .url(url):
                try await performUpload(subject: subject, request: uploadRequest, url: url)
            }
        } catch let error as NSError {
            subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
        }
        
        return subject
    }
    
    public func uploadMultipart(
        with request: NetworkMultipartUploadRequestProtocol,
        receive: DispatchQueue
    ) async throws -> PassthroughSubject<NetworkUploadResponse, NetworkError> {
        let subject = PassthroughSubject<NetworkUploadResponse, NetworkError>()
        
        do {
            let multipartRequest = try request.makeRequest()
            delegate.requestType = .upload
            
            let formData = request.makeFormBody()
            try await performUpload(subject: subject, request: multipartRequest, formData: formData)
        } catch let error as NSError {
            subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error)))
        }
        
        return subject
    }
}

@available(iOS 15.0, *)
private extension AsyncNetwork {
    func performUpload(
        subject: PassthroughSubject<NetworkUploadResponse, NetworkError>,
        request: URLRequest,
        data: Data
    ) async throws {
        let task = session.uploadTask(with: request, from: data) { (responseData, response, error) in
            if let error = error {
                subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
            } else if let responseData = responseData {
                subject.send(.response(data: responseData))
                subject.send(completion: .finished)
            } else {
                subject.send(completion: .failure(NetworkError.unknown))
            }
        }
        
        self.trackUploadProgress(for: task, subject: subject)
        task.resume()
    }
    
    func performUpload(
        subject: PassthroughSubject<NetworkUploadResponse, NetworkError>,
        request: URLRequest,
        url: URL
    ) async throws {
        let task = session.uploadTask(with: request, fromFile: url) { (responseData, response, error) in
            if let error = error {
                subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
            } else if let responseData = responseData {
                subject.send(.response(data: responseData))
                subject.send(completion: .finished)
            } else {
                subject.send(completion: .failure(NetworkError.unknown))
            }
        }
        
        self.trackUploadProgress(for: task, subject: subject)
        task.resume()
    }
    
    func performUpload(
        subject: PassthroughSubject<NetworkUploadResponse, NetworkError>,
        request: URLRequest,
        formData: Data
    ) async throws {
        let task = session.uploadTask(with: request, from: formData) { (responseData, response, error) in
            if let error = error {
                subject.send(completion: .failure(NetworkError.convertErrorToNetworkError(error: error as NSError)))
            } else if let responseData = responseData {
                subject.send(.response(data: responseData))
                subject.send(completion: .finished)
            } else {
                subject.send(completion: .failure(NetworkError.unknown))
            }
        }
        
        
        self.trackUploadProgress(for: task, subject: subject)
        task.resume()
    }
    
    func trackUploadProgress(
        for task: URLSessionUploadTask,
        subject: PassthroughSubject<NetworkUploadResponse, NetworkError>
    ) {
        _ = (task.progress as Progress).observe(\.fractionCompleted) { progress, _ in
            let percentage = Float(progress.fractionCompleted) * 100
            subject.send(.progress(percentage: percentage))
        }
    }
}
