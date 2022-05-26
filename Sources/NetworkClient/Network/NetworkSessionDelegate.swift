import Foundation
import Combine

public enum SSLPinning {
    case certificatePinning(certificate: SecCertificate, hash: String)
    case publicKeyPinning(hash: String)
}

protocol NetworkSessionDelegateProtocol: URLSessionTaskDelegate {
    var progressSubject: CurrentValueSubject<(id: Int, progress: Double), Never> { get }
}

final class NetworkSessionDelegate: NSObject, NetworkSessionDelegateProtocol {
    
    var progressSubject: CurrentValueSubject<(id: Int, progress: Double), Never>
    private var pinning: SSLPinning?
    
    init(pinning: SSLPinning? = nil,
         progressSubject: CurrentValueSubject<(id: Int, progress: Double),
         Never> = .init((id: 0, progress: 0.0))) {
        
        self.pinning = pinning
        self.progressSubject = progressSubject
    }
    
    private func updateProgress(_ task: URLSessionTask) {
        self.progressSubject.send((
            id: task.taskIdentifier,
            progress: task.progress.fractionCompleted
        ))
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                  URLCredential?) -> Swift.Void) {
        
        guard let pinning = pinning else {
            print("SSL Pinning Disabled, Using default handling.")
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
            return
        }
        
        guard (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust),
              let serverTrust = challenge.protectionSpace.serverTrust else {
                  completionHandler(.cancelAuthenticationChallenge, nil)
                  return
              }
        
        DispatchQueue.global().async {
            SecTrustEvaluateAsyncWithError(serverTrust,
                                           DispatchQueue.global()) { [weak self]
                (trust,
                 result,
                 error) in
                
                if result {
                    
                    var result: Bool? = false
                    
                    switch pinning {
                        case let .certificatePinning(certificate, hash):
                            result = self?.cetificatePinning(certificate: certificate,
                                                             hash: hash,
                                                             serverTrust: serverTrust)
                        case let .publicKeyPinning(hash):
                            result = self?.publicKeyPinning(serverTrust: serverTrust,
                                                            hash: hash,
                                                            trust: trust)
                    }
                    
                    completionHandler( result == true
                                       ? .useCredential
                                       : .cancelAuthenticationChallenge,
                                       result == true
                                       ? URLCredential(trust: serverTrust)
                                       : nil )
                } else {
                    print("Trust failed: \(error!.localizedDescription)") // Log these errors to metrics
                }
            }
        }
    }
    
    
    func urlSession( _ session: URLSession,
                     task: URLSessionTask,
                     didSendBodyData bytesSent: Int64,
                     totalBytesSent: Int64,
                     totalBytesExpectedToSend: Int64) {
        updateProgress(task)
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        updateProgress(downloadTask)
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        updateProgress(downloadTask)
    }
}

private extension NetworkSessionDelegate {
    
    func publicKeyPinning(serverTrust:SecTrust,
                          hash: String,
                          trust: SecTrust)-> Bool {
        
        if let serverPublicKey = SecTrustCopyKey(trust),
           let serverPublicKeyData: NSData =  SecKeyCopyExternalRepresentation(serverPublicKey, nil) {
            let keyHash = serverPublicKeyData.description.sha256()
            return keyHash == hash ? true : false
        }
        return false
    }
    
    
    func cetificatePinning(certificate: SecCertificate,
                           hash: String,
                           serverTrust: SecTrust)-> Bool {
        
        let serverCertificateData:NSData = SecCertificateCopyData(certificate)
        let certHash = serverCertificateData.description.sha256()
        return certHash == hash ? true : false
    }
}
