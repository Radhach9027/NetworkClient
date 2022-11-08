import Combine
import Foundation

final class NetworkSessionDelegate: NSObject,
    URLSessionTaskDelegate,
    URLSessionDelegate,
    URLSessionDownloadDelegate,
    URLSessionDataDelegate,
    URLSessionWebSocketDelegate {
    enum RequestType {
        case upload, download
    }

    var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    var downloadProgressSubject: PassthroughSubject<NetworkDownloadResponse, NetworkError> = .init()
    var uploadProgressSubject: PassthroughSubject<NetworkUploadResponse, NetworkError> = .init()
    var saveToLocation: URL?
    var requestType: RequestType = .download
    private var pinning: SSLPinning?
    private var logger: NetworkLoggerProtocol?

    init(
        pinning: SSLPinning? = nil,
        logger: NetworkLoggerProtocol? = nil,
        urlSessionDidFinishEvents: ((URLSession) -> Void)? = nil
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

        // Set SSL policies for domain name check
        let policies = NSMutableArray()
        policies.add(SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString?))
        SecTrustSetPolicies(serverTrust, policies)

        authenticationChallenge(
            pinning: pinning,
            serverTrust: serverTrust,
            completionHandler: completionHandler
        )
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
        debugPrint("NetworkSessionDelegate === progress \(progress) === downloadTask")
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

        switch requestType {
        case .upload:
            uploadError(error: error, url: url)
        case .download:
            downloadError(error: error, url: url, session: session)
        }
    }

    // MARK: URLSessionUpload_Download Finish delegate

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        urlSessionDidFinishEvents?(session)
    }
    
    // MARK: URLSessionWebSocketDelegate delegates
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        print("Web Socket did connect")
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        print("Web Socket did disconnect")
    }
}

private extension NetworkSessionDelegate {
    enum Constants {
        static let downloadFailedMessage = "Failed to download the given url = %@"
        static let uploadFailedMessage = "Failed to upload the given url = %@"
        static let downloadToLocationTitle = "Download To Location"
        static let downloadToLocationMessage = "Failed to save the url to given location"
    }

    func downloadError(error: Error, url: URL, session: URLSession) {
        let error: NetworkError = .init(
            title: .download,
            code: .downloadCode,
            errorMessage: .some(error.localizedDescription),
            userMessage: String(format: Constants.downloadFailedMessage, url as CVarArg)
        )

        guard let logger = logger else {
            return sendDownloadErrorSubject(error: error)
        }

        logger.logRequest(
            url: url,
            error: error,
            type: .error,
            privacy: .open
        )

        sendDownloadErrorSubject(error: error)
        guard let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data else {
            debugPrint("Download failed")
            return
        }
        session.downloadTask(withResumeData: resumeData).resumeTask()
    }

    func sendDownloadErrorSubject(error: NetworkError) {
        downloadProgressSubject.send(completion: .failure(error))
        downloadProgressSubject.send(completion: .finished)
    }

    func uploadError(error: Error, url: URL) {
        let error: NetworkError = .init(
            title: .upload,
            code: .uploadCode,
            errorMessage: .some(error.localizedDescription),
            userMessage: String(format: Constants.uploadFailedMessage, url as CVarArg)
        )

        guard let logger = logger else {
            return sendUploadErrorSubject(error: error)
        }

        logger.logRequest(
            url: url,
            error: error,
            type: .error,
            privacy: .open
        )

        sendUploadErrorSubject(error: error)
    }

    func sendUploadErrorSubject(error: NetworkError) {
        uploadProgressSubject.send(completion: .failure(error))
        uploadProgressSubject.send(completion: .finished)
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
                title: .download,
                code: .downloadCode,
                errorMessage: .some(fileError.localizedDescription),
                userMessage: Constants.downloadToLocationMessage
            )))
        }
    }

    func authenticationChallenge(
        pinning: SSLPinning,
        serverTrust: SecTrust,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void
    ) {
        DispatchQueue.global().async {
            SecTrustEvaluateAsyncWithError(
                serverTrust,
                DispatchQueue.global()
            ) {
                _,
                    result,
                    error in

                if result {
                    var result: Bool = false
                    switch pinning {
                    case let .certificatePinning(certificate):
                        result = pinning.cetificatePinning(
                            localCertificate: certificate,
                            serverTrust: serverTrust
                        )
                    case let .publicKeyPinning(hashes, domain):
                        result = pinning.publicKeyPinning(
                            serverTrust: serverTrust,
                            hashes: hashes,
                            domain: domain
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
}
