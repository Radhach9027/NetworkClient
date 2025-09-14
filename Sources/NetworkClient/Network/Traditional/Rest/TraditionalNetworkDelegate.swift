import Foundation

final class TraditionalNetworkSessionDelegate: NSObject,
    URLSessionTaskDelegate,
    URLSessionDelegate,
    URLSessionDownloadDelegate,
    URLSessionDataDelegate,
    URLSessionWebSocketDelegate {
    enum RequestType {
        case upload, download
    }

    var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    var saveToLocation: URL?
    var requestType: RequestType = .download
    private var pinning: SSLPinning?
    private var logger: NetworkLoggerProtocol?
    var isSocketConnected: Bool = false
    var downloadProgressHandler: ((Float) -> Void)?
    var uploadProgressHandler: ((Float) -> Void)?
    var downloadCompletionHandler: ((URL?, NetworkError?) -> Void)?
    var uploadCompletionHandler: ((Data?, NetworkError?) -> Void)?
      
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
        downloadProgressHandler?(progress)
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let givenLocation = saveToLocation else {
            downloadCompletionHandler?(location, nil)
            return
        }

        save(
            to: givenLocation,
            downloadedUrl: location,
            downloadTask: downloadTask
        )
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
        uploadProgressHandler?(progress)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        uploadCompletionHandler?(data, nil)
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
}

private extension TraditionalNetworkSessionDelegate {
    enum Constants {
        static let downloadFailedMessage = "Failed to download the given url = %@"
        static let uploadFailedMessage = "Failed to upload the given url = %@"
        static let downloadToLocationTitle = "Download To Location"
        static let downloadToLocationMessage = "Failed to save the url to given location"
    }

    func downloadError(
        error: Error,
        url: URL,
        session: URLSession
    ) {
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
        downloadCompletionHandler?(nil, error)
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
        uploadCompletionHandler?(nil, error)
    }

    func save(
        to file: URL,
        downloadedUrl: URL,
        downloadTask: URLSessionDownloadTask
    ) {
        do {
                   let destinationURL = file.appendingPathComponent(downloadTask.originalRequest!.url!.lastPathComponent)
                   if FileManager.default.fileExists(atPath: destinationURL.path) {
                       try FileManager.default.removeItem(at: destinationURL)
                   }
                   try FileManager.default.moveItem(at: downloadedUrl, to: destinationURL)
                   downloadCompletionHandler?(destinationURL, nil)
               } catch let fileError {
                   let error = NetworkError(
                       title: .download,
                       code: .downloadCode,
                       errorMessage: .some(fileError.localizedDescription),
                       userMessage: Constants.downloadToLocationMessage
                   )
                   downloadCompletionHandler?(nil, error) 
               }
    }

    func authenticationChallenge(
        pinning: SSLPinning,
        serverTrust: SecTrust,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void
    ) {
        DispatchQueue.global().async {
              var result: SecTrustResultType = .invalid
              let status = SecTrustEvaluate(serverTrust, &result)

              if status == errSecSuccess {
                  var isPinningValid = false
                  switch pinning {
                  case let .certificatePinning(certificate):
                      isPinningValid = pinning.cetificatePinning(
                          localCertificate: certificate,
                          serverTrust: serverTrust
                      )
                  case let .publicKeyPinning(hashes, domain):
                      isPinningValid = pinning.publicKeyPinning(
                          serverTrust: serverTrust,
                          hashes: hashes,
                          domain: domain
                      )
                  }

                  completionHandler(
                      isPinningValid ? .useCredential : .cancelAuthenticationChallenge,
                      isPinningValid ? URLCredential(trust: serverTrust) : nil
                  )
              } else {
                  debugPrint("Trust evaluation failed: \(status)")
                  completionHandler(.cancelAuthenticationChallenge, nil)
              }
          }
    }
}
