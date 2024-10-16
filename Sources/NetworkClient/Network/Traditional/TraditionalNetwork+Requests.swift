import Foundation

@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
public extension TraditionalNetwork {
    func request(
        for request: NetworkRequestProtocol,
        receive: DispatchQueue,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        handleRequest(
            request: request,
            receive: receive) { result in
                completion(result)
            }
    }
    
    func request<T>(
        for request: NetworkRequestProtocol,
        codable: T.Type,
        receive: DispatchQueue,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) where T: Decodable {
        handleRequest(request: request, receive: receive) { result in
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try NetworkError.dataDecoding(codable: T.self, data: data)
                    completion(.success(decodedObject))
                } catch let error as NetworkError {
                    completion(.failure(error))
                } catch {
                    completion(.failure(NetworkError.unknown))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
private extension TraditionalNetwork {
    func handleRequest(
           request: NetworkRequestProtocol,
           receive: DispatchQueue,
           completion: @escaping (Result<Data, NetworkError>) -> Void
       ) {
           do {
               var urlRequest = try request.makeRequest()
               for interceptor in requestInterceptors {
                   let result = interceptor.adapt(&urlRequest)
                   switch result {
                   case .success:
                       continue
                   case .failure(let error):
                       completion(.failure(error))
                       return
                   }
               }
               session.dataTask(with: urlRequest) { data, response, error in
                   receive.async {
                       if let error = error {
                           let networkError = NetworkError.convertErrorToNetworkError(error: error as NSError)
                           self.logError(
                            networkError,
                            url: urlRequest.url
                           )
                           completion(.failure(networkError))
                           return
                       }

                       guard let httpResponse = response as? HTTPURLResponse else {
                           let networkError = NetworkError.unknown
                           self.logError(
                            networkError,
                            url: urlRequest.url
                           )
                           completion(.failure(networkError))
                           return
                       }

                       if let validationError = NetworkError.validateHTTPError(urlResponse: httpResponse) {
                           self.logError(
                            validationError,
                            url: urlRequest.url
                           )
                           completion(.failure(validationError))
                           return
                       }

                       guard let data = data else {
                           let networkError = NetworkError.unknown
                           self.logError(
                            networkError,
                            url: urlRequest.url
                           )
                           completion(.failure(networkError))
                           return
                       }

                       completion(.success(data))
                   }
               }.resume()
           } catch let error as NetworkError {
               completion(.failure(error))
           } catch {
               let networkError = NetworkError.unknown
               completion(.failure(networkError))
           }
       }
    
    func logError(
        _ error: NetworkError,
        url: URL?
    ) {
        if let logger = logger,
           let url = url {
            logger.logRequest(
                url: url,
                error: error,
                type: .error,
                privacy: .encrypt
            )
        }
    }
}
