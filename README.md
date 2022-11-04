# Network Client

* It uses URLSession.


# Key Features:

* Request, bulk requests(serial, concurrent)

* Upload, multi-part with progress

* Download with progress

* Sslpinning (certificate, pinning)


# Network (default):
   let session = Network(config: .default())
   
# Network (default with sslpinning):
   var defaultSession: Network {
        switch SecCertificate.loadFromBundle() {
        case let .success(certificate):
            return Network(
                config: .default(),
                pinning: .certificatePinning(certificate: certificate)
            )
        case .failure:
            return Network(config: .default())
        }
   }

# Network (background):
   var session: Network {
         .init(
                config: .background(identifer: Bundle.identifier),
                urlSessionDidFinishEvents: urlSessionDidFinishEvents
            )

   }
   
 # Network (background with sslpinning):
   var session: Network {
         .init(
                config: .background(identifer: Bundle.identifier),
                pinning: .certificatePinning(certificate: certificate),
                urlSessionDidFinishEvents: urlSessionDidFinishEvents
            )

   }

# SSLPinning from host app:
* It would be nice to create an SecCertificate extension and use it.

enum SecCertificateError<S, F> {
    case success(S)
    case failure(F)
}

extension SecCertificate {
    enum Certificate {
        static let name = "your certificate name from bundle"
    }

    static var hashKey: String {
        "put your public key"
    }

    static func loadFromBundle(
        certName: String = Certificate.name,
        bundle: Bundle = Bundle.main
    ) -> SecCertificateError<SecCertificate, String> {
        guard let filePath = bundle.path(
            forResource: certName,
            ofType: "cer"
        ) else {
            return .failure("Couldn't load resource from \(bundle)")
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
                return .failure("Couldn't convert data as SecCertificateCreateWithData for file \(filePath)")
            }
            return .success(certificate)

        } catch {
            return .failure(error.localizedDescription)
        }
    }
}


### Note: Open for Constructive feedback.

