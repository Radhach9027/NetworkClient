import Foundation

@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
public protocol URLSessionTraditionalProtocol {
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask
}


@available(
    iOS,
    deprecated: 13.0,
    message: "Use Combine or Async for iOS 13 and above."
)
extension URLSession: URLSessionTraditionalProtocol {}
