import Combine
import Foundation

public enum SSLPinning {
    case certificatePinning(certificate: SecCertificate, hash: String)
    case publicKeyPinning(hash: String)
}

final class NetworkSessionDelegate: NSObject,
    URLSessionTaskDelegate,
    URLSessionDelegate,
    URLSessionDownloadDelegate {
    var urlSessionDidFinishEvents: ((URLSession) -> Void)?
    var progressSubject: PassthroughSubject<DownloadNetworkResponse, NetworkError> = .init()
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
                                           DispatchQueue.global()) { [weak self]
                trust,
                    result,
                    error in

                if result {
                    var result: Bool? = false

                    switch pinning {
                    case let .certificatePinning(certificate, hash):
                        result = self?.cetificatePinning(
                            certificate: certificate,
                            hash: hash,
                            serverTrust: serverTrust
                        )
                    case let .publicKeyPinning(hash):
                        result = self?.publicKeyPinning(
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

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        progressSubject.send(.progress(percentage: progress))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let givenLocation = saveToLocation else {
            progressSubject.send(.response(data: location))
            progressSubject.send(completion: .finished)
            return
        }
        save(to: givenLocation, downloadedUrl: location)
    }

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
        progressSubject.send(completion: .failure(.convertErrorToNetworkError(error: error as NSError)))
        guard let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data else {
            debugPrint("Download failed")
            return
        }
        session.downloadTask(withResumeData: resumeData).resume()
    }

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
            progressSubject.send(completion: .failure(.init(
                title: Constants.downloadToLocationTitle,
                code: Constants.errorCode,
                errorMessage: fileError.localizedDescription,
                userMessage: Constants.downloadToLocationMessage
            )))
        }
    }

    func publicKeyPinning(
        serverTrust: SecTrust,
        hash: String,
        trust: SecTrust
    ) -> Bool {
        if let serverPublicKey = SecTrustCopyKey(trust),
           let serverPublicKeyData: NSData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) {
            let keyHash = serverPublicKeyData.description.sha256
            return keyHash == hash ? true : false
        }
        return false
    }

    func cetificatePinning(
        certificate: SecCertificate,
        hash: String,
        serverTrust: SecTrust
    ) -> Bool {
        let serverCertificateData: NSData = SecCertificateCopyData(certificate)
        let certHash = serverCertificateData.description.sha256
        return certHash == hash ? true : false
    }
}
