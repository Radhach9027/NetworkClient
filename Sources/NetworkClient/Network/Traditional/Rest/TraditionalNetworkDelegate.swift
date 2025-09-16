import Foundation

final class TraditionalNetworkSessionDelegate: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    private var urlSessionDidFinishEvents: ((URLSession) -> Void)?
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
    
    // MARK: - URLAuthenticationChallenge
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust here; let the system handle everything else.
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // If pinning is disabled, let ATS/default validation run.
        guard let pinning = pinning else {
            logger?.log("SSL Pinning disabled, using default handling.", type: .error, privacy: .open)
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let policies = NSMutableArray()
        policies.add(SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString))
        SecTrustSetPolicies(serverTrust, policies)
        
        evaluateTrustAndPin(
            pinning: pinning,
            serverTrust: serverTrust,
            completionHandler: completionHandler
        )
    }
    
    private func evaluateTrustAndPin(
        pinning: SSLPinning,
        serverTrust: SecTrust,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var trustOK = false
            
            if #available(iOS 13.0, *) {
                var trustError: CFError?
                trustOK = SecTrustEvaluateWithError(serverTrust, &trustError)
                if let err = trustError {
                    self.logger?.log("Trust evaluation failed: \(err)", type: .error, privacy: .open)
                }
            } else {
                var result = SecTrustResultType.invalid
                let status = SecTrustEvaluate(serverTrust, &result)
                trustOK = (status == errSecSuccess) &&
                (result == .unspecified || result == .proceed)
            }
            
            guard trustOK else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            
            let isPinnedOK: Bool
            switch pinning {
                case let .certificatePinning(certificate):
                    isPinnedOK = pinning.cetificatePinning(
                        localCertificate: certificate,
                        serverTrust: serverTrust
                    )
                case let .publicKeyPinning(hashes, domain):
                    isPinnedOK = pinning.publicKeyPinning(
                        serverTrust: serverTrust,
                        hashes: hashes,
                        domain: domain
                    )
            }
            
            if isPinnedOK {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                self.logger?.log("SSL pinning failed", type: .error, privacy: .open)
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate (background downloads)
extension TraditionalNetworkSessionDelegate {
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {}
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        urlSessionDidFinishEvents?(session)
    }
}

