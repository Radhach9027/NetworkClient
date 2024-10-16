import Foundation
import Combine

public protocol NetworkRetryInterceptor {
    func shouldRetry(
        _ request: URLRequest,
        dueTo error: Error
    ) async throws -> Bool
}

public protocol TraditionalNetworkRetryInterceptor {
    func shouldRetry(
        _ request: URLRequest,
        dueTo error: Error
    ) -> Result<Bool, NetworkError>
}

public protocol CombineNetworkRetryInterceptor {
    func shouldRetry(
        _ request: URLRequest,
        dueTo error: Error
    ) -> AnyPublisher<Bool, NetworkError>
}
