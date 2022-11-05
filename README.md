# Network Client

* It uses URLSession.
* Built over SPM, add to your package dependency https://github.com/Radhach9027/NetworkClient and point to **main** branch.


### Key Features:

* Request, bulk requests(serial, concurrent)

* Upload, multi-part with progress

* Download with progress

* Sslpinning (certificate, publicKey)


### Create required extensions as below in your app, in-order to make your job easy:

* Create an extension like SecCertificate+Extensions from host app: (Loading SecCertificate from bundle if exists)

```
enum SecCertificateResult<S, F> {
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
    ) -> SecCertificateResult<SecCertificate, String> {
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

* Create an extension like Network+Extensions from host app: (SSLPinning is optional, make changes accordingly when you don't pin certificates)

```
import Foundation
import NetworkClient

extension Network {
    class var defaultSession: Network {
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

    class func backgroundSession(urlSessionDidFinishEvents: @escaping (URLSession) -> Void) -> Network {
        switch SecCertificate.loadFromBundle() {
        case let .success(certificate):
            return Network(
                config: .background(identifer: Bundle.identifier),
                pinning: .certificatePinning(certificate: certificate),
                urlSessionDidFinishEvents: urlSessionDidFinishEvents
            )
        case .failure:
            return Network(
                config: .background(identifer: Bundle.identifier),
                urlSessionDidFinishEvents: urlSessionDidFinishEvents
            )
        }
    }
    
    ### Without sslpinning (default):
    class var defaultSession: Network {
         return Network(config: .default())
    }
}
```
 
 
 
### Creating a sample request:
* In order to achieve this, we need to create an endpoint and conform NetworkRequestProtocol to it.

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

* Declaring Request Service
```
   private lazy var service = RequestService(network: Network.defaultSession)
```

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
```

* Consuming codable request.

 ```
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
```

  * Consuming serial requests.
  
 ```
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

### Creating a sample multi-part upload request:
* In order to achieve this, we need to create an endpoint and conform to NetworkMultipartUploadRequestProtocol to it.

```
import Foundation
import NetworkClient

enum UploadMultipartEndPoint {
    case image(name: String, data: Data, mimeType: String)
}

extension UploadMultipartEndPoint: NetworkMultipartUploadRequestProtocol {
    var baseURL: String {
        "your base endpoint"
    }

    var urlPath: String {
        "/uploadPicture"
    }

    var httpMethod: NetworkRequestMethod {
        .post
    }

    var boundary: String {
        UUID().uuidString
    }

    var urlComponents: URLComponents? {
        return URLComponents(string: baseURL + urlPath)
    }

    var httpHeaderFields: NetworkHTTPHeaderField? {
        .headerFields(fields: [.contentType: .multipartFormData(boundary: boundary)])
    }

    var multipartFormDataType: MultipartFormDataType {
        switch self {
        case let .image(name, data, mimeType):
            return .data(name: name, data: data, mimeType: mimeType)
        }
    }
}
```

### Making the upload request using the endpoint(UploadMultipartEndPoint):
* In order to achieve this, we'r creating a UploadMultipartService class and using the upload(endpoint: UploadMultipartEndPoint) func from the NetworkClient.

```
import Combine
import Foundation
import NetworkClient

final class UploadMultipartService: ObservableObject {
    private var network: NetworkProtocol

    init(network: NetworkProtocol) {
        self.network = network
    }

    func upload(endpoint: UploadMultipartEndPoint, receive: DispatchQueue) -> PassthroughSubject<UploadNetworkResponse, NetworkError> {
         network.uploadMultipart(with: endpoint, receive: .main)
    }
}
```

### Finally, consuming the UploadMultipartService:

* Declaring upload-multipart Service
```
    private lazy var service = UploadMultipartService(network: Network.defaultSession)
```

* Here we'r trying to upload an image to server on button click

```
    @IBAction func uploadMultipart(sender: UIButton) {
        if let data = image.image?.pngData() {
            service.upload(endpoint: .image(
                name: "profilePicture",
                data: data,
                mimeType: "img/png"
            ), receive: .main)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    switch result {
                    case .finished:
                        debugPrint("uploadMultipart finished")
                    case let .failure(error):
                        debugPrint(error.errorMessage.value)
                    }
                } receiveValue: { [weak self] response in
                    switch response {
                    case let .progress(percentage):
                        debugPrint("uploadMultipart percentage = \(percentage)")
                    case let .response(data):
                        debugPrint("uploadMultipart success = \(data)")
                    }
                }
                .store(in: &cancellable)
        }
    }
  ```

### Creating a sample download request:
* In order to achieve this, we need to create an endpoint and conform to NetworkDownloadRequestProtocol to it.

```
import Foundation
import NetworkClient

enum DownloadEndpoint {
    case image
}

extension DownloadEndpoint: NetworkDownloadRequestProtocol {
    var saveDownloadedUrlToLocation: URL? {
        nil // save to default
    }

    var urlPath: String {
        switch self {
        case .image:
            return "/jpeg/PIA08506.jpg"
        }
    }

    var httpMethod: NetworkRequestMethod {
        switch self {
        case .image:
            return .get
        }
    }

    var baseURL: String {
        switch self {
        case .image:
            return "https://photojournal.jpl.nasa.gov"
        }
    }

    var urlComponents: URLComponents? {
        return URLComponents(string: baseURL + urlPath)
    }
}
```

### Making the download request using the endpoint(DownloadEndpoint):
* In order to achieve this, we'r creating a DownloadService class and using the download(endpoint: DownloadEndpoint func from the NetworkClient.

```
import Combine
import Foundation
import NetworkClient

final class DownloadService: ObservableObject {
    private var network: NetworkProtocol

    init(network: NetworkProtocol) {
        self.network = network
    }

    func download(endpoint: DownloadEndpoint, receive: DispatchQueue) -> PassthroughSubject<DownloadNetworkResponse, NetworkError> {
         network.download(for: endpoint, receive: receive)
    }
}
```

### Finally, consuming the DownloadService:
* Declaring foreground download Service

```
    private lazy var service = DownloadService(network: Network.defaultSession)
```

* Declaring background download Service

```
    private lazy var service = DownloadService(
        network: Network.backgroundSession(urlSessionDidFinishEvents: { _ in
            DispatchQueue.main.async {
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                   let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                    appDelegate.backgroundSessionCompletionHandler = nil
                    completionHandler()
                }
            }
        })
    )
 ```
 
 * In order to know the events for BackgroundURLSession we need to confirm the below code snippet to the host app AppDelegate.

 
```
import UIKit
 
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var backgroundSessionCompletionHandler: (() -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(
        _: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        if identifier == Bundle.identifier {
            backgroundSessionCompletionHandler = completionHandler
        }
    }
}
 ```
 
 * Here we'r trying to download an image from server
```
    func download() {
        service.download(endpoint: .image, receive: .main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .finished:
                    debugPrint("ForegroundDownload finished")
                case let .failure(error):
                    debugPrint(error.errorMessage.value)
                }
            } receiveValue: { [weak self] response in
                switch response {
                case let .progress(percentage):
                     debugPrint("download percentage = \(percentage)")
                case let .response(url):
                     debugPrint(url)
                }
            }
            .store(in: &cancellable)
    }
  ```

### Development in-progress:
 * Conquerent requests.
 * Bulk uploads.
 * Bulk downloads.
 * Still working on the test cases part. will be covering unit & integration testing.
 * Need to address comments for required code snippets.
 * Need to create a client side server for real time issues.
 

### Open to contributors, Please follow Feature Branching Strategy and raise PR's.
