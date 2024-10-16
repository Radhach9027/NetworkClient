import Foundation
import Combine

public protocol NetworkRequestInterceptor {
    func adapt(_ request: inout URLRequest) async throws
    func handleError(
        _ error: Error,
        for request: URLRequest
    ) async throws
}

public protocol TraditionalNetworkRequestInterceptor {
    func adapt(_ request: inout URLRequest) -> Result<Void, NetworkError>
    func handleError(
        _ error: Error,
        for request: URLRequest
    ) -> Result<Void, NetworkError>
}

public protocol CombineNetworkRequestInterceptor {
    func adapt(_ request: inout URLRequest) -> AnyPublisher<Void, NetworkError>
    func handleError(
        _ error: Error,
        for request: URLRequest
    ) -> AnyPublisher<Void, NetworkError>
}
