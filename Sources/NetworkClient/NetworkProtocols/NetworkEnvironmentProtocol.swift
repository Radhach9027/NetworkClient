import Foundation

public protocol NetworkEnvironmentProtocol {
    var baseURL: String { get }
    var apiKey: String? { get }
}
