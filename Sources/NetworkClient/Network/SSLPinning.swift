import CryptoKit
import Foundation

public enum SSLPinning {
    case certificatePinning(certificate: SecCertificate)
    case publicKeyPinning(hashes: [String], domain: String?)
}

extension SSLPinning {
    func cetificatePinning(
        localCertificate: SecCertificate,
        serverTrust: SecTrust
    ) -> Bool {
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return false
        }
        let isServerTrusted = SecTrustEvaluateWithError(serverTrust, nil)
        let serverCertificateData: NSData = SecCertificateCopyData(serverCertificate)
        let localCertificateData: NSData = SecCertificateCopyData(localCertificate)
        return (isServerTrusted && serverCertificateData.isEqual(to: localCertificateData as Data))
            ? true
            : false
    }

    func publicKeyPinning(
        serverTrust: SecTrust,
        hashes: [String],
        domain: String?
    ) -> Bool {
        // Set SSL policies for domain name check, if needed
        if let domain = domain {
            let policies = NSMutableArray()
            policies.add(SecPolicyCreateSSL(true, domain as CFString))
            SecTrustSetPolicies(serverTrust, policies)
        }

        // For each certificate in the valid trust:
        for index in 0 ..< SecTrustGetCertificateCount(serverTrust) {
            // Get the public key data for the certificate at the current index of the loop.
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, index),
                  let publicKey = SecCertificateCopyKey(certificate),
                  let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
                return false
            }

            let keyHash = hash(data: (publicKeyData as NSData) as Data)
            if hashes.contains(keyHash) {
                return true
            }
        }
        return false
    }

    private func hash(data: Data) -> String {
        var keyWithHeader = Data(Self.rsa2048Asn1Header)
        keyWithHeader.append(data)
        if #available(iOS 13, *) {
            return Data(SHA256.hash(data: keyWithHeader)).base64EncodedString()
        } else {
            return keyWithHeader.sha256()
        }
    }

    private static var rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86,
        0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00,
    ]
}
