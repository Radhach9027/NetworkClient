import Foundation

extension URLSession {
    
    static func defaultSession(delegate: NetworkSessionDelegate) -> URLSession {
        URLSession(
            configuration: .defaultConfig,
            delegate: delegate,
            delegateQueue: nil
        )
    }
    
    static func backgroundSession(delegate: NetworkSessionDelegate) -> URLSession {
        URLSession(
            configuration: .backgroundConfig,
            delegate: delegate,
            delegateQueue: OperationQueue()
        )
    }
}
