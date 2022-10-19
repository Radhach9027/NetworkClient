import Combine
import Foundation

final class NetworkSessionDelegate: NSObject,
    URLSessionTaskDelegate,
    URLSessionDelegate,
    URLSessionDownloadDelegate,
    URLSessionDataDelegate {
    var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    var downloadProgressSubject: PassthroughSubject<DownloadNetworkResponse, NetworkError> = .init()
    var uploadProgressSubject: PassthroughSubject<UploadNetworkResponse, NetworkError> = .init()
    var saveToLocation: URL?
    private var pinning: SSLPinning?
    private var logger: NetworkLoggerProtocol?

    init(
        pinning: SSLPinning? = nil,
        logger: NetworkLoggerProtocol? = nil,
        urlSessionDidFinishEvents: ((URLSession) -> Void)?
    ) {
        self.pinning = pinning
        self.logger = logger
        self.urlSessionDidFinishEvents = urlSessionDidFinishEvents
    }

    // MARK: URLAuthenticationChallenge

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                      URLCredential?
        ) -> Swift.Void) {
        guard let pinning = pinning else {
            debugPrint("SSL Pinning Disabled, Using default handling.")
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        DispatchQueue.global().async {
            SecTrustEvaluateAsyncWithError(serverTrust,
                                           DispatchQueue.global()) {
                trust,
                    result,
                    error in

                if result {
                    var result: Bool? = false

                    switch pinning {
                    case let .certificatePinning(certificate, hash):
                        result = pinning.cetificatePinning(
                            certificate: certificate,
                            hash: hash,
                            serverTrust: serverTrust
                        )
                    case let .publicKeyPinning(hash):
                        result = pinning.publicKeyPinning(
                            serverTrust: serverTrust,
                            hash: hash,
                            trust: trust
                        )
                    }

                    completionHandler(
                        result == true
                            ? .useCredential
                            : .cancelAuthenticationChallenge,
                        result == true
                            ? URLCredential(trust: serverTrust)
                            : nil
                    )
                } else {
                    debugPrint("Trust failed: \(error!.localizedDescription)") // Log these errors to metrics
                }
            }
        }
    }

    // MARK: URLSessionDownload delegates

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        downloadProgressSubject.send(.progress(percentage: progress))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let givenLocation = saveToLocation else {
            downloadProgressSubject.send(.response(data: location))
            downloadProgressSubject.send(completion: .finished)
            return
        }
        save(to: givenLocation, downloadedUrl: location)
    }

    // MARK: URLSessionUpload delegates

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        uploadProgressSubject.send(.progress(percentage: progress))
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        uploadProgressSubject.send(.response(data: data))
        uploadProgressSubject.send(completion: .finished)
    }

    // MARK: URLSessionUpload_Download Error delegate

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error = error,
              let url = task.currentRequest?.url else {
            return
        }

        if let logger = logger {
            logger.logRequest(
                url: url,
                error: .init(
                    title: Constants.downloadFailedTitle,
                    code: Constants.errorCode,
                    errorMessage: Constants.downloadFailedMessage,
                    userMessage: .empty
                ),
                type: .error,
                privacy: .encrypt
            )
        }
        downloadProgressSubject.send(completion: .failure(.convertErrorToNetworkError(error: error as NSError)))
        guard let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data else {
            debugPrint("Download failed")
            return
        }
        session.downloadTask(withResumeData: resumeData).resume()
    }

    // MARK: URLSessionUpload_Download Finish delegate

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        urlSessionDidFinishEvents?(session)
    }
}

private extension NetworkSessionDelegate {
    enum Constants {
        static let downloadFailedTitle = "Download failed"
        static let downloadFailedMessage = "Failed to download the given url = %@"
        static let downloadToLocationTitle = "Download To Location"
        static let downloadToLocationMessage = "Failed to save the url to given location"
        static let errorCode = -222
    }

    func save(to file: URL, downloadedUrl: URL) {
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }

            try FileManager.default.copyItem(
                at: downloadedUrl,
                to: file
            )
        } catch let fileError {
            downloadProgressSubject.send(completion: .failure(.init(
                title: Constants.downloadToLocationTitle,
                code: Constants.errorCode,
                errorMessage: fileError.localizedDescription,
                userMessage: Constants.downloadToLocationMessage
            )))
        }
    }
}
