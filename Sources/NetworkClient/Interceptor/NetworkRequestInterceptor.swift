import Combine
import Foundation

@available(iOS 13.0, *)
public protocol AsyncNetworkRequestInterceptor {
    func adapt(_ request: inout URLRequest) async throws
    func handleError(
        _ error: Error,
        for request: URLRequest
    ) async throws
}

@available(iOS 13.0, *)
public protocol CombineNetworkRequestInterceptor {
    func adapt(_ request: inout URLRequest) -> AnyPublisher<Void, NetworkError>
    func handleError(
        _ error: Error,
        for request: URLRequest
    ) -> AnyPublisher<Void, NetworkError>
}

@available(iOS 11.0, *)
public protocol TraditionalNetworkRequestInterceptor {
    var id: InterceptorID { get }
    func adapt(_ request: inout URLRequest) -> Result<Void, NetworkError>
}
