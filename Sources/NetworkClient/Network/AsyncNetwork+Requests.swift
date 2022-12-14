import Combine
import Foundation

// MARK: Network Requests
@available(iOS 15.0, *)
public extension AsyncNetwork {
    func request(
        request: NetworkRequestProtocol,
        receive: DispatchQueue
    ) async throws -> AnyPublisher<Data, NetworkError> {
        do {
            let request = try request.makeRequest()
            let (data, response) = try await session.data(for: request, delegate: delegate)
            guard let error = NetworkError.validateHTTPError(urlResponse: response as? HTTPURLResponse) else {
                return Just(data)
                    .setFailureType(to: NetworkError.self)
                    .eraseToAnyPublisher()
            }
            throw error
        } catch let error as NSError {
            return Fail(error: NetworkError.convertErrorToNetworkError(error: error))
                .eraseToAnyPublisher()
        }
    }
}
