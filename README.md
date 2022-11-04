# Network Client

* It uses URLSession.


### Key Features:

* Request, bulk requests(serial, concurrent)

* Upload, multi-part with progress

* Download with progress

* Sslpinning (certificate, pinning)


### Network (default):
```
   let session = Network(config: .default())
```
   
### Network (default with sslpinning):
```
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
```

### Network (background):
```
var session: Network {
         .init(
                config: .background(identifer: Bundle.identifier),
                urlSessionDidFinishEvents: urlSessionDidFinishEvents
            )

   }
  ```
   
 ### Network (background with sslpinning):
```
   var session: Network {
         .init(
                config: .background(identifer: Bundle.identifier),
                pinning: .certificatePinning(certificate: certificate),
                urlSessionDidFinishEvents: urlSessionDidFinishEvents
            )

   }
  ```
### SSLPinning from host app:
* It would be nice to create an SecCertificate extension and use it

```
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
```
### Creating a sample request:
* In order to achieve this we need to create an endpoint and conform NetworkRequestProtocol to it.

```
import NetworkClient

enum RequestEndPoint {
    case fetch
}

extension RequestEndPoint: NetworkRequestProtocol {
    var apiKey: String? {
        "Demo_Key"
    }

    var baseURL: String {
        "https://api.nasa.gov"
    }

    var urlPath: String {
        "/planetary/apod"
    }

    var urlComponents: URLComponents? {
        var components = URLComponents(string: baseURL + urlPath)
        components?.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        return components
    }

    var httpMethod: NetworkRequestMethod {
        .get
    }
}
```

### Making the request using the endpoint(RequestEndPoint):
* In order to achieve this, we'r creating a RequestService class and using all three exposed request types from the NetworkClient.

```
import Combine
import Foundation
import NetworkClient

final class RequestService: ObservableObject {
    private var network: NetworkProtocol

    init(network: NetworkProtocol) {
        self.network = network
    }

    func request(endpoint: RequestEndPoint, receive: DispatchQueue) -> AnyPublisher<Data, NetworkError> {
         network.request(for: endpoint, receive: receive)
    }
    
    func request<T>(endpoint: RequestEndPoint, codable: T.Type, receive: DispatchQueue) -> AnyPublisher<T, NetworkError> where T: Decodable {
         network.request(for: endpoint, codable: T.self, receive: receive)
    }
    
    func serialRequests(endpoints: [RequestEndPoint], receive: DispatchQueue) -> PassthroughSubject<Data?, NetworkError> {
         network.serialRequests(for: endpoints, receive: receive)
    }
}
```

### Finally, consuming the RequestService:

* Consuming data request.

 ```
    func dataRequest() {
        service.request(endpoint: .fetch, receive: .main)
            .receive(on: DispatchQueue.main)
            .decode(type: NasaAstronomy.self, decoder: JSONDecoder())
            .sink { [weak self] result in
                switch result {
                case .finished:
                    debugPrint("Request finished")
                case let .failure(error):
                if let error = error as? NetworkError {
                     debugPrint(error.errorMessage.value)
                 }
               }
            } receiveValue: { [weak self] model in
                debugPrint(model)
            }
            .store(in: &cancellable)
    }

* Consuming codable request.

    func codableRequest() {
        service.request(endpoint: .fetch, codable: NasaAstronomy.self, receive: .main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .finished:
                    debugPrint("Request finished")
                case let .failure(error):
                     debugPrint(error.errorMessage.value)
                }
            } receiveValue: { [weak self] model in
                debugPrint(model)
            }
            .store(in: &cancellable)
    }

  * Consuming serial requests.
  
  func serialRequests() {
        service.serialRequests(endpoints: [.fetch, .fetch, .fetch], receive: .main)
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .decode(type: NasaAstronomy.self, decoder: JSONDecoder())
            .sink { [weak self] result in
                switch result {
                case .finished:
                    debugPrint("serialRequests finished")
                case let .failure(error):
                  if let error = error as? NetworkError {
                     debugPrint(error.errorMessage.value)
                  }
                }
            } receiveValue: { [weak self] model in
                     debugPrint(model)
            }
            .store(in: &cancellable)
    }
```
