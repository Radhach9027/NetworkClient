import Combine
import Foundation

public enum RetryStates {
    case retry, noRetry, retryWithDelay(Double)
}

@available(iOS 13.0, *)
public protocol AsyncNetworkRetryInterceptor {
    var id: InterceptorID { get }
    func shouldRetry(
        _ request: URLRequest,
        dueTo error: Error
    ) async throws -> Bool
}

@available(iOS 13.0, *)
public protocol CombineNetworkRetryInterceptor {
    var id: InterceptorID { get }
    func shouldRetry(
        _ request: URLRequest,
        dueTo error: Error
    ) -> AnyPublisher<Bool, NetworkError>
}

@available(iOS 11.0, *)
public protocol TraditionalNetworkRetryInterceptor {
    var id: InterceptorID { get }
    func shouldRetry(
        _ request: NetworkRequestProtocol,
        dueTo error: NetworkError,
        completion: @escaping (Result<RetryStates, NetworkError>) -> Void
    )
}
