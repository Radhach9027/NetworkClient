import Foundation

public enum SSLPinning {
    case certificatePinning(certificate: SecCertificate, hash: String)
    case publicKeyPinning(hash: String)
}

extension SSLPinning {
    
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
